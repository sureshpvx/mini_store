class WelcomeEmailWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome_email(user).deliver_now
    Rails.logger.info "📧 Welcome email sent to #{user.email}"
  end
end