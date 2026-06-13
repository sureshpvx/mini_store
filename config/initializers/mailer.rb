# Shared Action Mailer settings for ALL environments
Rails.application.config.action_mailer.delivery_method = :smtp

Rails.application.config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:mailtrap, :username),
  password: Rails.application.credentials.dig(:mailtrap, :password),
  address: 'live.smtp.mailtrap.io',
  host: 'live.smtp.mailtrap.io',
  port: 587,
  authentication: :login,
  enable_starttls_auto: true
}
