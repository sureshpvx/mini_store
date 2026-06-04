# app/controllers/oauth_callbacks_controller.rb
class OauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user.persisted?
      sign_in(user)
      redirect_to root_path, notice: 'Signed in with Google!'
    else
      redirect_to new_user_session_path, alert: 'Could not sign in with Google.'
    end
  end

  def failure
    redirect_to new_user_session_path, alert: 'Google authentication failed. Please try again.'
  end
end