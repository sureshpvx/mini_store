class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many_attached :images
  #has_one_attached :video

  has_many :cart_items, dependent: :destroy

  belongs_to :category

end
