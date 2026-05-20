class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
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

  private

  def create_cart_for_customer
    return unless customer?

    create_cart
  end

end
