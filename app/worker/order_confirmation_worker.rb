class OrderConfirmationWorker
  include Sidekiq::Worker

  def perform(order_id)
    order = Order.find(order_id)
    user = order.user

    UserMailer.order_confirmation_email(user, order).deliver_now
    Rails.logger.info "📧 Order confirmation sent to #{user.email} for Order ##{order_id}"
  end
end