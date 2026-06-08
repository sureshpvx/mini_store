class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, polymorphic: true, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { where(created_at: 30.days.ago..) }
  scope :newest_first, -> { order(created_at: :desc) }

  def unread?
    read_at.nil?
  end

  def mark_as_read!
    update(read_at: Time.current) if unread?
  end

  def self.mark_all_as_read!(user)
    user.notifications.unread.update_all(read_at: Time.current)
  end
end
