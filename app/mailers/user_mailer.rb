class UserMailer < ApplicationMailer
  default from: 'Hypee Store <noreply@hypee.shop>'

  def welcome_email(user)
    @user = user
    @url = Rails.env.production? ? 'https://hypee.shop/login' : 'http://localhost:3000/login'
    mail(to: @user.email, subject: 'Welcome to Hypee Store!')
  end

  def order_confirmation_email(user, order)
    @user = user
    @order = order
    @url = Rails.env.production? ? "https://hypee.shop/orders/#{@order.id}" : "http://localhost:3000/orders/#{@order.id}"

    mail(to: @user.email, subject: "Order ##{@order.id} Confirmed!")
  end
end