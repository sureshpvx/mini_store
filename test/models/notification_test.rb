require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "unread scope returns only notifications without read_at" do
    user = users(:one)
    read_notif = Notification.create!(user: user, kind: "order_placed", title: "Test", message: "Read")
    read_notif.update!(read_at: Time.current)
    unread_notif = Notification.create!(user: user, kind: "order_shipped", title: "Test", message: "Unread")

    results = Notification.unread
    assert_includes results, unread_notif
    assert_not_includes results, read_notif
  end

  test "mark_as_read! sets read_at timestamp" do
    user = users(:one)
    notification = Notification.create!(user: user, kind: "order_placed", title: "Test", message: "Msg")
    assert_nil notification.read_at
    notification.mark_as_read!
    assert_not_nil notification.read_at
  end

  test "mark_as_read! is idempotent" do
    user = users(:one)
    notification = Notification.create!(user: user, kind: "order_placed", title: "Test", message: "Msg")
    notification.mark_as_read!
    first_read_at = notification.read_at
    notification.mark_as_read!
    assert_equal first_read_at, notification.read_at
  end

  test "mark_all_as_read! marks all user notifications as read" do
    user = users(:one)
    Notification.create!(user: user, kind: "order_placed", title: "Test", message: "1")
    Notification.create!(user: user, kind: "order_shipped", title: "Test", message: "2")

    assert_equal 2, user.notifications.unread.count
    Notification.mark_all_as_read!(user)
    assert_equal 0, user.notifications.unread.count
  end

  test "newest_first orders by created_at descending" do
    user = users(:one)
    old = Notification.create!(user: user, kind: "order_placed", title: "Old", message: "1")
    newer = Notification.create!(user: user, kind: "order_shipped", title: "New", message: "2")

    results = Notification.newest_first
    assert_equal newer, results.first
    assert_equal old, results.last
  end

  test "unread? returns true when read_at is nil" do
    user = users(:one)
    notification = Notification.create!(user: user, kind: "order_placed", title: "Test", message: "Msg")
    assert notification.unread?
    notification.mark_as_read!
    assert_not notification.unread?
  end
end
