class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.bigint :user_id, null: false
      t.string :actor_type
      t.bigint :actor_id
      t.string :kind, null: false
      t.string :title, null: false
      t.text :message
      t.string :url
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, [:user_id, :created_at]
    add_index :notifications, [:actor_type, :actor_id]
    add_foreign_key :notifications, :users
  end
end
