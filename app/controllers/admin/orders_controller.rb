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
    if @order.update(order_params)
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
end