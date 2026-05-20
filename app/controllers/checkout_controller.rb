class CheckoutController < ApplicationController

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

end