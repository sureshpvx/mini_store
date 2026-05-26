require 'stringio'
class Admin::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :set_new_product, only: [:index]

  def index
    @pagy, @products = pagy(
      Product.includes(:category, images_attachments: :blob)
             .order(created_at: :desc),
      limit: 10
    )
  end

  def show
    @related_products = Product.where(category_id: @product.category_id)
                               .where.not(id: @product.id)
                               .limit(4)
  end

  def new
    @product = Product.new
    load_categories
  end

  def create
    files = Array(params.dig(:product, :images)).reject(&:blank?)
    video_file = params.dig(:product, :video)

    if files.blank? && video_file.blank?
      @product = Product.new(base_product_params)
      @product.errors.add(:images, "must include at least one image or video")
      load_categories
      flash.now[:alert] = "Please attach at least one product image or video."
      render :new, status: :unprocessable_entity
      return
    end

    @product = Product.new(base_product_params)

    if @product.save
      @product.reload  # <-- KEY FIX: reload before attaching
      attach_media!(files, video_file)
      redirect_to admin_product_path(@product), notice: "Product created successfully."
    else
      load_categories
      flash.now[:alert] = @product.errors.full_messages.to_sentence.presence || "Failed to create product."
      render :new, status: :unprocessable_entity
    end
  rescue => e
    load_categories
    flash.now[:alert] = "Upload failed: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def edit
    load_categories
  end

  def update
    files = Array(params.dig(:product, :images)).reject(&:blank?)
    video_file = params.dig(:product, :video)

    if @product.update(base_product_params)
      attach_media!(files, video_file) if files.any? || video_file.present?
      redirect_to admin_product_path(@product), notice: "#{@product.name} updated successfully."
    else
      load_categories
      flash.now[:alert] = @product.errors.full_messages.to_sentence.presence || "Update failed."
      render :edit, status: :unprocessable_entity
    end
  rescue => e
    load_categories
    flash.now[:alert] = "Upload failed: #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path, notice: "Product removed from collection."
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError
    redirect_to admin_products_path, alert: "Cannot delete: product is in active orders or carts."
  rescue => e
    redirect_to admin_products_path, alert: "Delete failed: #{e.message}"
  end

  private

  def attach_media!(files, video_file)
    files.each do |file|
      next unless file.is_a?(ActionDispatch::Http::UploadedFile)

      file.rewind if file.respond_to?(:rewind)
      content = file.read

      @product.images.attach(
        io: StringIO.new(content),
        filename: secure_filename(file.original_filename),
        content_type: file.content_type
      )
    end

    if video_file.is_a?(ActionDispatch::Http::UploadedFile)
      video_file.rewind if video_file.respond_to?(:rewind)
      content = video_file.read

      @product.video.attach(
        io: StringIO.new(content),
        filename: secure_filename(video_file.original_filename),
        content_type: video_file.content_type
      )
    end
  end

  def secure_filename(original)
    "#{SecureRandom.hex(8)}_#{original.downcase.gsub(/[^a-z0-9.]/, '_')}"
  end

  def base_product_params
    params.require(:product).permit(
      :name, :description, :price, :stock, :category_id
    )
  end

  def set_product
    @product = Product.includes(:category, images_attachments: :blob)
                      .friendly
                      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_products_path, alert: "Product not found."
  end

  def load_categories
    @categories = Category.includes(:subcategories)
                          .where(parent_id: nil)
                          .order(:name)
  end

  def set_new_product
    @product = Product.new
  end

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end