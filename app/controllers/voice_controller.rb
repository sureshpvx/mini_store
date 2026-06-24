class VoiceController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:message]

  def index
    # Renders the voice chat UI page
  end

  def message
    user_text = params[:message].to_s.strip

    if user_text.empty?
      render json: { error: 'Message cannot be empty' }, status: :bad_request
      return
    end

    client = AiClient.new
    ai_response = client.generate(user_text)

    render json: { reply: ai_response }
  rescue AiClient::ConnectionError => e
    Rails.logger.error "AI connection error: #{e.message}"
    render json: { error: 'AI service is unavailable. Please try again later.' }, status: :service_unavailable
  rescue AiClient::Error => e
    Rails.logger.error "AI error: #{e.message}"
    render json: { error: 'Something went wrong with the AI. Please try again.' }, status: :internal_server_error
  end
end
