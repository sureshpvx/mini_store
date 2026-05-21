class CheckoutController < ApplicationController
  before_action :ensure_cart_has_items, only: [:show]


  def show

    @cart = current_cart

    if user_signed_in?

      @addresses =
        current_user.addresses.order(created_at: :desc)

    else

      @addresses =
        Address.where(id: session[:guest_address_id])

    end

  end

  def store_address
    session[:guest_address_id] = params[:address_id]

    head :ok
  end

  private
  def ensure_cart_has_items
    if current_cart.cart_items.empty?
      redirect_to root_path, alert: "Your cart is empty. Add some products first."
    end
  end

end