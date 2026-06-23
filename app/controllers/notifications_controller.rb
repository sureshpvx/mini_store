class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    if Notification.table_exists?
      @notifications = current_user.notifications.newest_first
      @unread_count = current_user.notifications.unread.count
    else
      @notifications = Notification.none
      @unread_count = 0
    end
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to(@notification.url.presence || notifications_path) }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to notifications_path, alert: "Notification not found"
  end

  def mark_all_as_read
    Notification.mark_all_as_read!(current_user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: notifications_path }
    end
  end

  def count
    render json: { count: current_user.notifications.unread.count }
  end
end
