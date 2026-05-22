class Admin::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @products = pagy(
      Product.includes(
        :category
      ).order(created_at: :desc),
      limit: 10
    )
  end

  def new
    @product = Product.new
    load_categories
  end

  def create
    files = params.dig(:product, :images).to_a.reject(&:blank?)
    if files.blank?
      @product = Product.new(product_params.except(:images))
      @product.errors.add(:images, "must be attached")
      flash.now[:alert] = "Please attach at least one image for the product"
      load_categories
      render :new, status: :unprocessable_entity
      return
    end

    @product = nil
    success = false

    ActiveRecord::Base.transaction do
      @product = Product.new(product_params.except(:images))
      unless @product.save
        raise ActiveRecord::Rollback
      end

      @product.images.attach(files)
      # if attachments aren't present for some reason, rollback
      unless @product.images.attached?
        Rails.logger.error "Attachment failed for product creation"
        @product.errors.add(:images, "failed to attach")
        raise ActiveRecord::Rollback
      end

      success = true
    end

    unless success
      puts "Product create aborted in transaction"
      Rails.logger.warn "Product create aborted in transaction (admin=#{current_user&.id})"
      # Rebuild a new product instance for rendering form with errors where possible
      @product ||= Product.new(product_params.except(:images))
      load_categories
      flash.now[:alert] ||= "There was a problem creating the product and attaching images."
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to admin_product_path(@product), notice: "Product created"
  end
  def show
  end

  def edit
    load_categories
  end

  def update
    if @product.update(product_params)
      redirect_to admin_product_path(@product),
                  notice: "#{@product.name} updated successfully"
    else
      load_categories
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy

    redirect_to admin_products_path,
                notice: "Product removed from collection"
  end

  private

  def set_product
    @product = Product.friendly.find(params[:id])
  end

  def load_categories
    @categories = Category.includes(:subcategories)
                          .where(parent_id: nil)
  end

  def require_admin
    redirect_to root_path,
                alert: "Not authorized" unless current_user.admin?
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :price,
      :stock,
      :category_id,
      images: []
    )
  end
end