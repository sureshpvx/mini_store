# app/models/product.rb
class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  include PgSearch::Model
  multisearchable against: [:name, :description]

  pg_search_scope :search,
                  against: [:name, :description],
                  associated_against: { category: :name },
                  using: {
                    tsearch: { prefix: true, dictionary: "english" },
                    trigram: {}
                  }

  has_many_attached :images, dependent: :purge_later
  has_one_attached :video, dependent: :purge_later

  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items
  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category_id, presence: true

  # ===== DELETION HELPERS =====

  # Check if safe to delete (for UI warnings)
  def deletable?
    active_cart_items.none? && active_order_items.none?
  end

  # Users who have this in their cart RIGHT NOW
  def active_cart_users
    active_cart_items.includes(cart: :user).map { |ci| ci.cart.user }.compact
  end

  # Non-delivered, non-cancelled orders containing this product
  def active_orders
    active_order_items.includes(:order).map(&:order)
  end

  private

  def active_cart_items
    cart_items.joins(:cart).where(carts: { user_id: User.select(:id) })
  end

  def active_order_items
    order_items.joins(:order).where.not(orders: { status: [3, 4] }) # 3=delivered, 4=cancelled
  end
end