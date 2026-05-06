class Admin::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @products = Product.all
  end

  def new
    @product = Product.new
    @categories = Category.includes(:subcategories).where(parent_id: nil)

  end

  def show
    @product = Product.find(params[:id])
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to admin_product_path(@product), notice: "Product created successfully"
    else
      @categories = Category.includes(:subcategories).where(parent_id: nil)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end

  def product_params
    params.require(:product).permit(
      :name, :description, :price, :stock,
      :category_id,
      :video, images: []
    )
  end
end