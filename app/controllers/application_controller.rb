class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_cart

  protected

  def current_cart
    if session[:cart_id]
      Cart.find_by(id: session[:cart_id])
    else
      cart = Cart.create(
        user: current_user
      )

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
