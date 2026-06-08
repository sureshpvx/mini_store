class NotificationCreator
  KIND_CONFIG = {
    order_placed:       { title: "Order Confirmed",       icon: "check" },
    payment_confirmed:  { title: "Payment Confirmed",     icon: "card" },
    payment_failed:     { title: "Payment Failed",        icon: "alert" },
    order_shipped:      { title: "Order Shipped",         icon: "truck" },
    order_delivered:    { title: "Order Delivered",       icon: "package" },
    order_cancelled:    { title: "Order Cancelled",       icon: "x" }
  }.freeze

  def self.call(user:, kind:, actor: nil, message: nil, url: nil)
    config = KIND_CONFIG[kind.to_sym]
    return unless config

    Notification.create!(
      user: user,
      actor: actor,
      kind: kind.to_s,
      title: config[:title],
      message: message || default_message_for(kind, actor),
      url: url
    )
  end

  def self.default_message_for(kind, actor)
    case kind.to_sym
    when :order_placed
      "Your order ##{order_ref(actor)} has been placed successfully."
    when :payment_confirmed
      "Payment for order ##{order_ref(actor)} has been confirmed."
    when :payment_failed
      "Payment for order ##{order_ref(actor)} could not be verified."
    when :order_shipped
      "Your order ##{order_ref(actor)} is on its way!"
    when :order_delivered
      "Your order ##{order_ref(actor)} has been delivered."
    when :order_cancelled
      "Your order ##{order_ref(actor)} has been cancelled."
    else
      "You have a new notification."
    end
  end

  def self.order_ref(order)
    return "N/A" unless order&.id
    "HYPEE-#{order.id.to_s.rjust(4, '0')}"
  end
end
