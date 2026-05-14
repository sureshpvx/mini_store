class CartsController < ApplicationController
  def show
    @cart = current_cart
  end

  def add_item
    product = Product.find(params[:product_id])

    cart_item = current_cart.cart_items.find_or_initialize_by(
      product: product
    )

    if cart_item.new_record?
      cart_item.quantity = 1
    else
      cart_item.quantity += 1
    end

    cart_item.save!

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_back(
          fallback_location: root_path,
          notice: "#{product.name} added to your collection"
        )
      end
    end
  end

  def increase_quantity
    cart_item = current_cart.cart_items.find(params[:id])

    cart_item.increment!(:quantity)

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_back(
          fallback_location: cart_path
        )
      end
    end
  end

  def decrease_quantity
    cart_item = current_cart.cart_items.find(params[:id])

    if cart_item.quantity > 1
      cart_item.decrement!(:quantity)
    else
      cart_item.destroy
    end

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_back(
          fallback_location: cart_path
        )
      end
    end
  end

  def remove_item
    cart_item = current_cart.cart_items.find(params[:id])

    cart_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_back(
          fallback_location: cart_path,
          notice: "Item removed from cart"
        )
      end
    end
  end
end