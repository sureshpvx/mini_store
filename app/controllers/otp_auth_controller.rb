class OtpAuthController < ApplicationController

  def new
  end

  def send_otp
    otp = rand(100000..999999).to_s

    session[:otp] = otp
    session[:otp_phone_number] = params[:phone_number]
    session[:checkout_address_id] = params[:address_id]


    Rails.logger.info "OTP CODE: #{otp}"

    render turbo_stream: turbo_stream.replace(
      "otp_modal_content",
      partial: "otp_auth/verify_form"
    )
  end

  def verify

    if params[:otp] == session[:otp]

      phone_number =
        session[:otp_phone_number]

      user = User.find_by(
        phone_number: phone_number
      )

      unless user

        user = User.create!(
          email: "#{SecureRandom.hex(4)}@hypee.com",
          password: SecureRandom.hex(10),
          phone_number: phone_number,
          role: :customer
        )

      end

      guest_cart = current_cart

      sign_in(:user, user)

      address = Address.find_by(
        id: session[:guest_address_id]
      )

      if address.present? && address.user_id.nil?

        address.update!(user: user)

      end

      if guest_cart.present? && user.cart.present?

        guest_cart.cart_items.each do |item|

          existing_item =
            user.cart.cart_items.find_by(
              product_id: item.product_id
            )

          if existing_item

            existing_item.increment!(
              :quantity,
              item.quantity
            )

          else

            item.update!(
              cart_id: user.cart.id
            )

          end

        end

      end

      session.delete(:otp)

      if address.present?
        session[:auto_order_address_id] = address.id
      end
      redirect_to checkout_path(
                    auto_submit: true
                  )

    else

      redirect_to checkout_path,
                  alert: "Invalid OTP"

    end

  end

end