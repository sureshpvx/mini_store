class ProductsController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @products = pagy(
      Product.active.with_attached_images.includes(:category).order(created_at: :desc),
      limit: 12
    )
    @product_count = @pagy.count
  end

  def show
    @product = Product.active.with_attached_images.includes(:category).friendly.find(params[:id])
  end
end