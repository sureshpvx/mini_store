# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::BaseController
  def index
    @total_orders    = Order.count
    @total_customers = User.count
    @total_products  = Product.count
    @total_revenue   = Order.where(payment_status: 1).sum(:total_price)
  end
end