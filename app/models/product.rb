class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many_attached :images
  has_one_attached :video

  has_many :cart_items, dependent: :destroy

  belongs_to :category


  validates :name, :price, presence: true
  validate :debug_images

  def debug_images
    Rails.logger.error "=== IMAGES DEBUG ==="
    Rails.logger.error images.inspect
  end
end
