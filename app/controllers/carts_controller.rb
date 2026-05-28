class CartsController < ApplicationController
  def show
    @cart = current_cart
  end

  def buy_now
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i > 0 ? params[:quantity].to_i : 1

    # Set exact quantity for this product (replace if already in cart)
    cart_item = current_cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = quantity
    cart_item.save!

    @current_cart = nil  # bust cache

    redirect_to checkout_path
  end

  def add_item
    product = Product.find(params[:product_id])
    cart_item = current_cart.cart_items.find_or_initialize_by(product: product)

    if cart_item.new_record?
      cart_item.quantity = 1
    else
      cart_item.quantity += 1
    end

    cart_item.save!

    # Bust the cached cart so next render is fresh
    @current_cart = nil

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("cart_content", partial: "carts/cart_content") }
      format.html { redirect_back(fallback_location: root_path, notice: "#{product.name} added to your collection") }
    end
  end

  def increase_quantity
    cart_item = current_cart.cart_items.find_by(id: params[:id])

    if cart_item.nil?
      @current_cart = nil
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cart_content", partial: "carts/cart_content") }
        format.html { redirect_back(fallback_location: cart_path, alert: "Cart updated. Please refresh.") }
      end
      return
    end

    cart_item.update!(quantity: cart_item.quantity + 1)
    @current_cart = nil  # Bust cache

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("cart_content", partial: "carts/cart_content") }
      format.html { redirect_back(fallback_location: cart_path) }
    end
  end

  def decrease_quantity
    cart_item = current_cart.cart_items.find_by(id: params[:id])

    if cart_item.nil?
      @current_cart = nil
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cart_content", partial: "carts/cart_content") }
        format.html { redirect_back(fallback_location: cart_path, alert: "Cart updated. Please refresh.") }
      end
      return
    end

    if cart_item.quantity > 1
      cart_item.update!(quantity: cart_item.quantity - 1)
    else
      cart_item.destroy
    end

    @current_cart = nil  # Bust cache

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("cart_content", partial: "carts/cart_content") }
      format.html { redirect_back(fallback_location: cart_path) }
    end
  end

  def remove_item
    cart_item = current_cart.cart_items.find_by(id: params[:id])

    if cart_item
      cart_item.destroy
      notice = "Item removed from cart"
    else
      notice = "Item already removed"
    end

    @current_cart = nil  # Bust cache

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("cart_content", partial: "carts/cart_content") }
      format.html { redirect_back(fallback_location: cart_path, notice: notice) }
    end
  end
end