class MakeUserIdNullableInChatLogs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :chat_logs, :user_id, true
  end
end
