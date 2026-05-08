class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  def index
    @product = Product.new

  end

  private
  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, status: :forbidden, alert: "Admins only!"
    end
  end
end
