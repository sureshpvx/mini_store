class CartsController < ApplicationController
  def show
    @cart = current_cart
  end

  def add_item
    product = Product.find(params[:product_id])

    cart_item = current_cart.cart_items.find_or_initialize_by(
      product: product
    )

    cart_item.quantity ||= 0
    cart_item.quantity += 1

    cart_item.save!

    redirect_back(
      fallback_location: root_path,
      notice: "#{product.name} added to your collection"
    )
  end
end