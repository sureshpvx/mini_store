Rails.application.config.action_mailer.delivery_method = :mailtrap
Rails.application.config.action_mailer.mailtrap_settings = {
  api_key: ENV["MAILTRAP_API_KEY"]
}