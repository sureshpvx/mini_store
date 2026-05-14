class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders
                          .includes(order_items: :product)
                          .order(created_at: :desc)
  end

  def create
    cart = current_cart

    if cart.cart_items.empty?
      redirect_to root_path, alert: "Your cart is empty"
      return
    end

    ActiveRecord::Base.transaction do

      address = current_user.addresses.find(params[:address_id])

      order = current_user.orders.create!(
        total_price: cart.total_price,

        shipping_full_name: address.full_name,
        shipping_phone_number: address.phone_number,

        shipping_address_line_1: address.address_line_1,
        shipping_address_line_2: address.address_line_2,

        shipping_city: address.city,
        shipping_state: address.state,
        shipping_postal_code: address.postal_code,
        shipping_country: address.country
      )

      cart.cart_items.each do |cart_item|
        order.order_items.create!(
          product: cart_item.product,
          quantity: cart_item.quantity,
          price: cart_item.product.price
        )
      end

      cart.cart_items.destroy_all

      redirect_to order_path(order),
                  notice: "Order placed successfully"
    end
  end

  def show
    @order = current_user.orders.find(params[:id])
  end
end