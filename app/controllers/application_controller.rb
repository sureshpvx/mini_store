class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_cart

  protected

  def current_cart
    # ✅ logged in customer ALWAYS uses own cart
    if user_signed_in? && current_user.customer?
      current_user.cart

      # ✅ guest cart
    elsif session[:cart_id].present?
      Cart.find_by(id: session[:cart_id])

      # ✅ create guest cart
    else
      cart = Cart.create!

      session[:cart_id] = cart.id

      cart
    end
  end

  def after_sign_in_path_for(resource)
    # Check if the logged-in user is an admin
    if resource.is_a?(User) && resource.admin?
      # Redirect to the admin namespace root ("dashboard#index")
      admin_root_path
    else
      # Redirect to the standard root ("home#index") for customers
      super
    end
  end
end
