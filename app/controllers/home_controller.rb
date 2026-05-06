class HomeController < ApplicationController
  # Add this line to run the check before loading the index page
  before_action :redirect_admin_to_dashboard, only: [:index]

  def index
    @new_arrivals = Product.order(created_at: :desc).limit(4)
    # Your existing code (if any) is here
  end

  private

  def redirect_admin_to_dashboard
    # If the user is logged in AND is an admin, kick them to the dashboard
    if user_signed_in? && current_user.admin?
      redirect_to admin_root_path
    end
  end
end
