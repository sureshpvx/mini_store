class Address < ApplicationRecord
  belongs_to :user
  validates :full_name, presence: true
  validates :phone_number, presence: true
  validates :address_line_1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :postal_code, presence: true
  validates :country, presence: true
end
