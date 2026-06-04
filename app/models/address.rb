class Address < ApplicationRecord
  belongs_to :user, optional: true

  INDIA_STATES = %w[
    AP AR AS BR CG DL GA GJ HR HP JK JH KA KL MP MH MN ML MZ NL OR PB RJ SK
    TN TG TR UP UT WB AN CH DN DD LD PY
  ].freeze

  validates :full_name,      presence: true, length: { maximum: 100 }
  validates :phone_number,   presence: true,
            format: { with: /\A(\+91[\-\s]?)?[6-9]\d{9}\z/, message: "must be a valid Indian mobile number" }
  validates :address_line_1, presence: true, length: { maximum: 255 }
  validates :address_line_2, length: { maximum: 255 }, allow_blank: true
  validates :city,           presence: true, length: { maximum: 100 }
  validates :state,          presence: true, length: { is: 2 },
            inclusion: { in: INDIA_STATES, message: "must be a valid Indian state code" }
  validates :postal_code,    presence: true, length: { maximum: 20 },
            format: { with: /\A\d{6}\z/, message: "must be a valid 6-digit Indian PIN code" }
  validates :country,        presence: true, length: { is: 2 },
            inclusion: { in: %w[IN], message: "only Indian addresses are supported" }

  before_validation :normalize_fields

  private

  def normalize_fields
    self.country      = country&.to_s&.upcase&.strip
    self.state        = state&.to_s&.upcase&.strip
    self.postal_code  = postal_code&.to_s&.strip
    self.phone_number = phone_number&.to_s&.strip&.delete(" ")
  end
end