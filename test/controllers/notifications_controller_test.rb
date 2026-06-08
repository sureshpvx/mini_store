require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(
      email: "notif_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :customer
    )
    sign_in @user
  end

  test "index returns notifications for current user" do
    Notification.create!(user: @user, kind: "order_placed", title: "Test", message: "Msg")
    get notifications_path
    assert_response :success
  end

  test "index shows unread count" do
    Notification.create!(user: @user, kind: "order_placed", title: "Test", message: "Msg")
    get notifications_path
    assert_response :success
  end

  test "mark_as_read marks a single notification" do
    notification = Notification.create!(user: @user, kind: "order_placed", title: "Test", message: "Msg")
    assert notification.unread?
    patch mark_as_read_notification_path(notification)
    notification.reload
    assert_not notification.unread?
  end

  test "mark_all_as_read marks all user notifications" do
    Notification.create!(user: @user, kind: "order_placed", title: "Test", message: "1")
    Notification.create!(user: @user, kind: "order_shipped", title: "Test", message: "2")
    assert_equal 2, @user.notifications.unread.count

    patch mark_all_as_read_notifications_path
    assert_equal 0, @user.notifications.unread.count
  end

  test "count returns unread count as JSON" do
    Notification.create!(user: @user, kind: "order_placed", title: "Test", message: "Msg")
    get count_notifications_path
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["count"]
  end

  test "requires authentication" do
    sign_out @user
    get notifications_path
    assert_redirected_to new_user_session_path
  end
end
