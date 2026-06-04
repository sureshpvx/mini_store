class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :order_id,   presence: true
  validates :product_id, presence: true
  validates :quantity,   presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :price,      presence: true,
            numericality: { greater_than: 0 }

  def total_price
    price * quantity
  end
end