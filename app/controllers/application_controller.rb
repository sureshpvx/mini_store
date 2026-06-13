class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  helper_method :current_cart, :unread_notifications_count

  protected

  def unread_notifications_count
    return 0 unless user_signed_in?
    return 0 unless Notification.table_exists?
    @_unread_notifications_count ||= current_user.notifications.unread.count
  rescue ActiveRecord::StatementInvalid
    0
  end

  def current_cart
    @current_cart ||= build_current_cart
  end

  private

  def build_current_cart
    cart = find_or_create_cart
    preload_cart(cart)
  end

  def find_or_create_cart
    if user_signed_in? && current_user.customer?
      # Legacy users or post-db-drop: create cart if missing
      current_user.cart || current_user.create_cart

    elsif session[:cart_id].present?
      # Guest cart: look it up, clear stale session if cart was deleted
      Cart.find_by(id: session[:cart_id]).tap do |cart|
        session.delete(:cart_id) if cart.nil?
      end

    end || create_guest_cart
  end

  def create_guest_cart
    Cart.create!.tap { |cart| session[:cart_id] = cart.id }
  end

  def preload_cart(cart)
    Cart.includes(
      cart_items: {
        product: [
          :category,
          { images_attachments: :blob }
        ]
      }
    ).find(cart.id)
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.admin?
      admin_root_path
    else
      super
    end
  end
end