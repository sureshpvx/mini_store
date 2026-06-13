# config/initializers/omniauth.rb

if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             ENV["GOOGLE_CLIENT_ID"],
             ENV["GOOGLE_CLIENT_SECRET"],
             {
               scope: "email,profile",
               prompt: "select_account",
               image_aspect_ratio: "square",
               image_size: 50,
               access_type: "online"
             }
  end
end

OmniAuth.config.on_failure = proc do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end