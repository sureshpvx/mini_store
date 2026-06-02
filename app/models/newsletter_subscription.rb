# app/models/newsletter_subscription.rb
class NewsletterSubscription < ApplicationRecord
  validates :email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }
end