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

    # FIX: Reload cart to ensure fresh state before passing to AI client
    current_cart.reload if current_cart.persisted?

    client = AiClient.new(cart: current_cart, user: current_user)
    ai_response = client.generate(user_text)

    # Log the conversation
    log_chat(user_text, ai_response, 'success')

    response_data = { reply: ai_response }

    # Include action metadata for frontend
    if client.action_performed.present?
      response_data[:action] = client.action_performed
      # FIX: Reload cart count from DB, not cached value
      response_data[:cart_count] = current_cart.reload.total_items
    end

    render json: response_data
  rescue AiClient::ConnectionError => e
    error_msg = 'AI service is unavailable. Please try again later.'
    log_chat(user_text, error_msg, 'connection_error')
    Rails.logger.error "AI connection error: #{e.message}"
    render json: { error: error_msg }, status: :service_unavailable
  rescue AiClient::Error => e
    error_msg = 'Something went wrong with the AI. Please try again.'
    log_chat(user_text, error_msg, 'ai_error')
    Rails.logger.error "AI error: #{e.message}"
    render json: { error: error_msg }, status: :internal_server_error
  end

  private

  def log_chat(message, response, source)
    ChatLog.create!(
      user: current_user,
      message: message,
      response: response,
      source: source
    )
  rescue => e
    Rails.logger.error "Failed to log chat: #{e.message}"
  end
end