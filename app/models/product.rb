# app/models/product.rb
class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many_attached :images
  has_one_attached :video

  has_many :cart_items, dependent: :destroy
  has_many :orders, through: :order_items
  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category_id, presence: true
end