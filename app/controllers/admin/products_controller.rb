class Admin::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @products = pagy(
      Product.includes(
        :category,
        images_attachments: :blob
      ).order(created_at: :desc),
      limit: 10
    )
  end

  def new
    @product = Product.new
    load_categories
  end

  def create
    puts "STEP 1"

    @product = Product.new(
      name: params[:product][:name],
      description: params[:product][:description],
      price: params[:product][:price],
      stock: params[:product][:stock],
      category_id: params[:product][:category_id]
    )

    puts "STEP 2"

    @product.save!

    puts "STEP 3"

    if params[:product][:images].present?
      puts "STEP 4"

      @product.images.attach(params[:product][:images])

      puts "STEP 5"
    end

    redirect_to admin_products_path

  rescue => e
    puts "ERROR OCCURRED"
    puts e.class
    puts e.message
    puts e.backtrace.first(10)

    render plain: e.message
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