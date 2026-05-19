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
        shipping_country: address.country,

        payment_status: :unpaid,
        status: :pending
      )

      cart.cart_items.each do |cart_item|
        order.order_items.create!(
          product: cart_item.product,
          quantity: cart_item.quantity,
          price: cart_item.product.price
        )
      end

      # CREATE RAZORPAY ORDER
      razorpay_order = Razorpay::Order.create(
        amount: (order.total_price * 100).to_i,
        currency: "INR",
        receipt: "order_#{order.id}"
      )

      order.update!(
        razorpay_order_id: razorpay_order.id
      )

      # cart.cart_items.destroy_all

      redirect_to payment_order_path(order),
                  notice: "Order created. Proceed to payment."
    end
  end

  def payment
    @order = current_user.orders.find(params[:id])
  end

  def verify_payment
    order = current_user.orders.find(params[:id])

    razorpay_order_id = params[:razorpay_order_id]
    razorpay_payment_id = params[:razorpay_payment_id]
    razorpay_signature = params[:razorpay_signature]

    begin

      Razorpay::Utility.verify_payment_signature(
        razorpay_order_id: razorpay_order_id,
        razorpay_payment_id: razorpay_payment_id,
        razorpay_signature: razorpay_signature
      )

      order.update!(
        payment_status: :paid,
        razorpay_payment_id: razorpay_payment_id,
        razorpay_signature: razorpay_signature
      )

      current_cart.cart_items.destroy_all

      render json: {
        success: true,
        redirect_url: order_path(order)
      }

    rescue Razorpay::Errors::SignatureVerificationError

      order.update!(
        payment_status: :failed
      )

      render json: {
        success: false
      }, status: :unprocessable_entity

    end
  end

  def show
    @order = current_user.orders.find(params[:id])
  end
end