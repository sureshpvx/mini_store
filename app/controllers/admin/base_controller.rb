class Admin::BaseController < ApplicationController
  before_action :ensure_admin!

  layout "admin"

  private

  def ensure_admin!
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end
end
