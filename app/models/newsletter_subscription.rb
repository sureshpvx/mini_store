class NewsletterSubscription < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:email]

  validates :email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }
end