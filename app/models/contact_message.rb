class ContactMessage < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:name, :email, :message]

  validates :name,    presence: true, length: { maximum: 100 }
  validates :email,   presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
end