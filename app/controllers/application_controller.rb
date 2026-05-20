class ApplicationController < ActionController::Base
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_cart


  protected

  def current_cart

    @current_cart ||= begin

                        cart =
                          if user_signed_in? && current_user.customer?

                            current_user.cart

                          elsif session[:cart_id].present?

                            Cart.find_by(id: session[:cart_id])

                          else

                            new_cart = Cart.create!

                            session[:cart_id] = new_cart.id

                            new_cart

                          end

                        Cart.includes(
                          cart_items: {
                            product: [
                              :category,
                              { images_attachments: :blob }
                            ]
                          }
                        ).find(cart.id)

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
