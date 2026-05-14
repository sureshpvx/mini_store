class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = current_cart
    @addresses = current_user.addresses
  end
end