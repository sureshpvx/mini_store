class Product < ApplicationRecord
  has_many_attached :images
  has_one_attached :video

  has_many :cart_items, dependent: :destroy

  belongs_to :category


  validates :name, :price, presence: true
end
