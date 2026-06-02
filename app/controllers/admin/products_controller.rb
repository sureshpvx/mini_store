class Admin::ProductsController < Admin::BaseController
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
      begin
        attach_media!(files, video_file)
        redirect_to admin_products_path, notice: "Product created successfully."
      rescue => e
        Rails.logger.error "Media upload failed: #{e.message}"
        load_categories
        flash.now[:alert] = "Product saved but media upload failed: #{e.message}. Add media below."
        render turbo_stream: turbo_stream.replace(
          "modal-content",
          partial: "admin/products/form",
          locals: { product: @product }
        )
      end
    else
      load_categories
      flash.now[:alert] = @product.errors.full_messages.to_sentence.presence || "Failed to create product."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_categories
  end

  def update
    files = Array(params.dig(:product, :images)).reject(&:blank?)
    video_file = params.dig(:product, :video)

    if params[:remove_image_ids].present?
      @product.images.where(id: params[:remove_image_ids]).each(&:purge)
    end

    if params[:remove_video].present?
      @product.video.purge
    end

    if @product.update(base_product_params)
      if files.any? || video_file.present?
        begin
          attach_media!(files, video_file)
        rescue => e
          load_categories
          flash.now[:alert] = "Media upload failed: #{e.message}"
          render :edit, status: :unprocessable_entity
          return
        end
      end
      redirect_to admin_product_path(@product), notice: "#{@product.name} updated successfully."
    else
      load_categories
      flash.now[:alert] = @product.errors.full_messages.to_sentence.presence || "Update failed."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.soft_delete!
    redirect_to admin_products_path, notice: "Product archived. Hidden from store, order history intact."
  rescue => e
    redirect_to admin_products_path, alert: "Archive failed: #{e.message}"
  end

  def restore
    @product = Product.unscoped.friendly.find(params[:id])
    @product.restore!
    redirect_to admin_products_path, notice: "Product restored to store."
  rescue => e
    redirect_to admin_products_path, alert: "Restore failed: #{e.message}"
  end
  
  private

  def attach_media!(files, video_file)
    files.each do |file|
      next unless file.is_a?(ActionDispatch::Http::UploadedFile)

      begin
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: secure_filename(file.original_filename),
          content_type: file.content_type,
          service_name: :cloudinary
        )
        @product.images.attach(blob)
      rescue NoMethodError => e
        raise e unless e.message.include?('preview_image')
      end
    end

    if video_file.is_a?(ActionDispatch::Http::UploadedFile)
      begin
        blob = ActiveStorage::Blob.create_and_upload!(
          io: video_file,
          filename: secure_filename(video_file.original_filename),
          content_type: video_file.content_type,
          service_name: :cloudinary
        )
        @product.video.attach(blob)
      rescue NoMethodError => e
        raise e unless e.message.include?('preview_image')
      end
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