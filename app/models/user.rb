class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  include PgSearch::Model
  multisearchable against: [:email, :phone_number]
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { customer: 0, admin: 1 }
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :addresses, dependent: :destroy
  validates :phone_number,
            uniqueness: true,
            allow_nil: true

  after_create :create_cart_for_customer

  # ── Google OAuth ──
  def self.from_omniauth(auth)
    # 1. Find existing user by Google account
    user = find_by(provider: auth.provider, uid: auth.uid)

    # 2. If not found, try to link by email (user signed up via OTP/Devise before)
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

    # 3. If still not found, create a new user
    unless user
      user = new(
        email: auth.info.email,
        provider: auth.provider,
        uid: auth.uid,
        avatar_url: auth.info.image,
        oauth_token: auth.credentials.token,
        role: :customer        # default to customer
      )
      # Devise requires a password even for OAuth users
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
end