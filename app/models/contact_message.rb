# app/models/contact_message.rb
class ContactMessage < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:name, :email, :message]
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, length: { minimum: 10, maximum: 2000 }
end