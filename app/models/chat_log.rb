class ChatLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :message, presence: true
  validates :response, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }

  # Analytics
  def self.top_queries
    group(:message)
      .select('message, COUNT(*) as count')
      .order('count DESC')
      .limit(10)
  end

  def self.resolution_rate
    total = count
    return 0 if total.zero?
    
    # Count responses that don't contain error messages
    successful = where.not("response ILIKE ?", "%error%").count
    (successful.to_f / total * 100).round(2)
  end
end
