# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::BaseController
  def index
    @pagy, @users = pagy(
      User.order(created_at: :desc),
      limit: 20
    )
  end
end