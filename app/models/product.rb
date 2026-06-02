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
  has_many :order_items, dependent: :nullify  # Changed from :restrict_with_error
  has_many :orders, through: :order_items
  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category_id, presence: true

  # ===== SOFT DELETE =====

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current, stock: 0)
  end

  def deleted?
    deleted_at.present?
  end

  def restore!
    update!(deleted_at: nil)
  end

  # Override destroy to use soft delete by default
  def destroy
    soft_delete!
  end

  # Hard destroy for admin force delete (optional)
  def hard_destroy!
    super_destroy
  end
end