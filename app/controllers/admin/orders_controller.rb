# app/controllers/admin/orders_controller.rb
class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [:show, :update]

  def index
    @pagy, @orders = pagy(
      Order.includes(:user, order_items: :product)
           .order(created_at: :desc),
      limit: 20
    )
  end

  def show
  end

  def update
    new_status = order_params[:status]
    if new_status == "cancelled" && !@order.cancelled?
      begin
        @order.cancel_and_restore_stock!
        notify_customer(:order_cancelled)
        redirect_to admin_orders_path, notice: "Order cancelled and stock restored."
        return
      rescue => e
        redirect_to admin_orders_path, alert: "Could not cancel: #{e.message}"
        return
      end
    end

    if @order.update(order_params)
      notify_customer_status_change(new_status)
      redirect_to admin_orders_path, notice: "Order updated"
    else
      redirect_to admin_orders_path, alert: "Could not update order"
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status, :payment_status)
  end

  STATUS_NOTIFICATION_MAP = {
    "shipped"   => :order_shipped,
    "delivered" => :order_delivered
  }.freeze

  def notify_customer_status_change(new_status)
    kind = STATUS_NOTIFICATION_MAP[new_status]
    notify_customer(kind) if kind
  end

  def notify_customer(kind)
    return unless @order.user
    NotificationCreator.call(
      user: @order.user,
      kind: kind,
      actor: @order,
      url: order_path(@order)
    )
  end
end