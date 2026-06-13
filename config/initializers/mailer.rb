Rails.application.config.action_mailer.delivery_method = :smtp
Rails.application.config.action_mailer.smtp_settings = {
  user_name: ENV["MAILTRAP_USERNAME"],
  password: ENV["MAILTRAP_PASSWORD"],
  address: 'live.smtp.mailtrap.io',
  host: 'live.smtp.mailtrap.io',
  port: 587,
  authentication: :login,
  enable_starttls_auto: true
}