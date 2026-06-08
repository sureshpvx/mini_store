module ApplicationHelper
  include Pagy::Frontend

  def unread_notifications_count
    return 0 unless user_signed_in?
    @_unread_notifications_count ||= current_user.notifications.unread.count
  end
end
