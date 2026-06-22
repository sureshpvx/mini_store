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
  has_many :order_items, dependent: :nullify
  has_many :orders, through: :order_items
  belongs_to :category

  validates :name,        presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :price,       presence: true, numericality: { greater_than: 0 }
  validates :stock,       presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category_id, presence: true

  scope :active,  -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def active_cart_users
    User.joins(cart: :cart_items)
        .where(cart_items: { product_id: id })
        .distinct
  end

  def in_stock?(requested = 1)
    stock >= requested
  end

  def low_stock?
    stock <= 5
  end

  def soft_delete!
    update!(deleted_at: Time.current, stock: 0)
  end

  def deleted?
    deleted_at.present?
  end

  def restore!
    update!(deleted_at: nil)
  end

  def destroy
    soft_delete!
  end

  def hard_destroy!
    super_destroy
  end

  def deduct_stock!(amount)
    with_lock do
      current = stock || 0
      if current < amount
        raise "Only #{current} in stock, requested #{amount}"
      end
      update!(stock: current - amount)
    end
  end

  def restore_stock!(amount)
    with_lock do
      update!(stock: (stock || 0) + amount)
    end
  end

  def record_view!(session)
    return if session[:viewed_products]&.include?(id)

    increment!(:views_count)
    session[:viewed_products] ||= []
    session[:viewed_products] << id
  end
end