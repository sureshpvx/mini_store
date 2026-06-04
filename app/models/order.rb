class Order < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:shipping_full_name, :razorpay_order_id, :shipping_phone_number]

  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4
  }

  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    failed: 2,
    refunded: 3
  }

  validates :user_id,     presence: true
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :status,      presence: true
  validates :payment_status, presence: true

  validates :shipping_full_name,      presence: true, length: { maximum: 100 }
  validates :shipping_phone_number,   presence: true,
            format: { with: /\A(\+91[\-\s]?)?[6-9]\d{9}\z/, message: "must be a valid Indian mobile number" }
  validates :shipping_address_line_1, presence: true, length: { maximum: 255 }
  validates :shipping_address_line_2, length: { maximum: 255 }, allow_blank: true
  validates :shipping_city,           presence: true, length: { maximum: 100 }
  validates :shipping_state,          presence: true, length: { is: 2 },
            inclusion: { in: Address::INDIA_STATES, message: "must be a valid Indian state code" }
  validates :shipping_postal_code,    presence: true, length: { maximum: 20 },
            format: { with: /\A\d{6}\z/, message: "must be a valid 6-digit Indian PIN code" }
  validates :shipping_country,        presence: true, length: { is: 2 },
            inclusion: { in: %w[IN], message: "only India is supported" }

  validates :razorpay_order_id,   presence: true, on: :update
  validates :razorpay_payment_id, length: { maximum: 100 }, allow_blank: true
  validates :razorpay_signature, length: { maximum: 255 }, allow_blank: true

  before_validation :normalize_shipping_fields

  private

  def normalize_shipping_fields
    self.shipping_country     = shipping_country&.to_s&.upcase&.strip
    self.shipping_state       = shipping_state&.to_s&.upcase&.strip
    self.shipping_postal_code = shipping_postal_code&.to_s&.strip
    self.shipping_phone_number = shipping_phone_number&.to_s&.strip&.delete(" ")
  end
end