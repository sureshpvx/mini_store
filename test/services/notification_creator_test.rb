require "test_helper"

class NotificationCreatorTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "creator_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :customer
    )
  end

  test "creates notification with valid kind" do
    assert_difference "Notification.count", 1 do
      NotificationCreator.call(user: @user, kind: :order_placed)
    end
  end

  test "does not create notification with invalid kind" do
    assert_no_difference "Notification.count" do
      NotificationCreator.call(user: @user, kind: :invalid_kind)
    end
  end

  test "sets actor and generates default message" do
    order = Order.create!(user: @user, total_price: 100, status: :pending, payment_status: :unpaid,
                          shipping_full_name: "Test", shipping_phone_number: "9999999999",
                          shipping_address_line_1: "1 Test St", shipping_city: "Mumbai",
                          shipping_state: "MH", shipping_postal_code: "400001", shipping_country: "India")
    notification = NotificationCreator.call(user: @user, kind: :order_placed, actor: order)
    assert_equal order, notification.actor
    assert_includes notification.message, "HYPEE-"
  end

  test "allows custom message" do
    notification = NotificationCreator.call(user: @user, kind: :order_shipped, message: "Custom message")
    assert_equal "Custom message", notification.message
  end

  test "sets url when provided" do
    notification = NotificationCreator.call(user: @user, kind: :order_delivered, url: "/orders/1")
    assert_equal "/orders/1", notification.url
  end
end
