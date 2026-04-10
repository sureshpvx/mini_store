class HomeController < ApplicationController

  before_action :authenticate_user!
  def index
    @is_admin = current_user&.admin?
  end
end
