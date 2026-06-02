class HomeController < ApplicationController
  before_action :redirect_admin_to_dashboard, only: [:index]

  def index
    @new_arrivals = Product
                      .active
                      .includes(:category)
                      .with_attached_images
                      .order(created_at: :desc)
                      .limit(4)
  end

  private

  def redirect_admin_to_dashboard
    redirect_to admin_root_path if user_signed_in? && current_user.admin?
  end
end