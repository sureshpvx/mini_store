class OtpAuthController < ApplicationController
  OTP_EXPIRY      = 5.minutes
  RESEND_COOLDOWN = 60.seconds
  MAX_ATTEMPTS    = 3

  def new
  end

  def send_otp
    store_phone_and_address
    generate_and_send_otp

    Rails.logger.info "OTP: #{session[:otp]} for #{session[:otp_phone_number]}"

    render turbo_stream: [
      turbo_stream.replace("otp_modal_content", partial: "otp_auth/verify_form", locals: { remaining: 0 }),
      turbo_stream.append("flash-container", partial: "shared/flash_message",
                          locals: { type: :notice, message: "OTP: #{session[:otp]}", timeout: 3000 })
    ]
  end

  def resend_otp
    unless resend_allowed?
      return render turbo_stream: turbo_stream.replace(
        "otp-resend-wrapper",
        partial: "otp_auth/resend_button",
        locals: { remaining: cooldown_remaining }
      )
    end

    generate_and_send_otp
    Rails.logger.info "OTP RESENT: #{session[:otp]}"

    render turbo_stream: [
      turbo_stream.replace("otp-resend-wrapper", partial: "otp_auth/resend_button", locals: { remaining: RESEND_COOLDOWN }),
      turbo_stream.append("flash-container", partial: "shared/flash_message",
                          locals: { type: :notice, message: "OTP: #{session[:otp]}", timeout: 3000 })
    ]
  end

  def verify
    return handle_expired      if otp_expired?
    return handle_max_attempts if max_attempts_reached?

    increment_attempts

    if params[:otp].to_s.strip == session[:otp].to_s
      process_success
    else
      handle_invalid
    end
  end

  private

  # --- OTP lifecycle ---

  def store_phone_and_address
    code   = params[:country_code].to_s.strip
    number = params[:phone_number].to_s.gsub(/\D/, "")
    session[:otp_phone_number] = "#{code} #{number}"
    # Do NOT touch session[:guest_address_id] here — the phone form doesn't send it
  end

  def generate_and_send_otp
    session[:otp]            = rand(100000..999999).to_s
    session[:otp_generated_at] = Time.current.to_i
    session[:otp_attempts]     = 0
  end

  def otp_expired?
    return true unless session[:otp_generated_at]
    Time.current.to_i - session[:otp_generated_at] > OTP_EXPIRY
  end

  def resend_allowed?
    return true unless session[:otp_generated_at]
    Time.current.to_i - session[:otp_generated_at] >= RESEND_COOLDOWN
  end

  def cooldown_remaining
    return 0 unless session[:otp_generated_at]
    [RESEND_COOLDOWN - (Time.current.to_i - session[:otp_generated_at]), 0].max
  end

  def max_attempts_reached?
    session[:otp_attempts].to_i >= MAX_ATTEMPTS
  end

  def increment_attempts
    session[:otp_attempts] = session[:otp_attempts].to_i + 1
  end

  # --- Error handlers ---

  def handle_expired
    redirect_to checkout_path, alert: "OTP expired. Please request a new one."
  end

  def handle_max_attempts
    redirect_to checkout_path, alert: "Too many attempts. Please request a new OTP."
  end

  def handle_invalid
    remaining = MAX_ATTEMPTS - session[:otp_attempts].to_i
    redirect_to checkout_path, alert: "Invalid OTP. #{remaining} attempt#{'s' unless remaining == 1} remaining."
  end

  # --- Success flow ---

  def process_success
    phone = session[:otp_phone_number]
    code, number = phone.split(" ", 2)

    user = User.find_by(country_code: code, phone_number: number) || User.create!(
      email:        "#{SecureRandom.hex(4)}@hypee.com",
      password:     SecureRandom.hex(10),
      country_code: code,
      phone_number: number,
      role:         :customer
    )

    # CAPTURE GUEST CART BEFORE sign_in changes current_cart
    guest_cart = current_cart

    sign_in(:user, user)

    # Ensure user has a cart
    user_cart = user.cart || user.create_cart

    merge_cart(guest_cart, user_cart)
    assign_guest_address(user)

    cleanup_session
    redirect_to checkout_path(auto_submit: true)
  end

  def merge_cart(guest_cart, user_cart)
    return unless guest_cart.present? && guest_cart.id != user_cart.id

    guest_cart.cart_items.each do |item|
      existing = user_cart.cart_items.find_by(product_id: item.product_id)
      if existing
        existing.increment!(:quantity, item.quantity)
        item.destroy
      else
        item.update!(cart_id: user_cart.id)
      end
    end

    guest_cart.reload.destroy
    session.delete(:cart_id)
  end

  def assign_guest_address(user)
    # CheckoutController stores address as :guest_address_id
    address = Address.find_by(id: session[:guest_address_id])

    # Fallback: unassigned address with same phone number
    address ||= Address.where(user_id: nil, phone_number: user.phone_number).order(created_at: :desc).first

    return unless address.present?

    address.update!(user: user) if address.user_id.nil?
    session[:auto_order_address_id] = address.id
  end

  def cleanup_session
    session.delete(:otp)
    session.delete(:otp_generated_at)
    session.delete(:otp_attempts)
    session.delete(:otp_phone_number)
    session.delete(:guest_address_id)
    session.delete(:cart_id)
    # NOTE: intentionally NOT deleting :auto_order_address_id
  end
end