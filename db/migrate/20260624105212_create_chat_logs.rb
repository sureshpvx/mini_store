class CreateChatLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.text :response
      t.string :source

      t.timestamps
    end
  end
end
