class User < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:email, :phone_number]

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { customer: 0, admin: 1 }

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :phone_number,
            uniqueness: true,
            allow_nil: true,
            format: { with: /\A(\+91[\-\s]?)?[6-9]\d{9}\z/, message: "must be a valid Indian mobile number" },
            if: -> { phone_number.present? }

  validates :country_code, presence: true, length: { maximum: 5 }
  validates :role,         presence: true
  validates :provider,     length: { maximum: 50 },  allow_blank: true
  validates :uid,          length: { maximum: 100 }, allow_blank: true
  validates :avatar_url,   length: { maximum: 500 }, allow_blank: true
  validates :oauth_token,  length: { maximum: 500 }, allow_blank: true

  after_create :create_cart_for_customer
  after_commit :enqueue_welcome_email, on: :create

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)

    if user.nil?
      user = find_by(email: auth.info.email)
      if user
        user.update!(
          provider: auth.provider,
          uid: auth.uid,
          avatar_url: auth.info.image,
          oauth_token: auth.credentials.token
        )
      end
    end

    unless user
      user = new(
        email: auth.info.email,
        provider: auth.provider,
        uid: auth.uid,
        avatar_url: auth.info.image,
        oauth_token: auth.credentials.token,
        role: :customer
      )
      user.password = Devise.friendly_token[0, 20]
      user.save!
    end

    user
  end

  private

  def create_cart_for_customer
    return unless customer?
    create_cart
  end

  def enqueue_welcome_email
    WelcomeEmailWorker.perform_async(id)
  rescue => e
    Rails.logger.warn "WelcomeEmailWorker could not be enqueued: #{e.message}"
  end
end