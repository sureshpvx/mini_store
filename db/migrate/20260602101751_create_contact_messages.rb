class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string  :name,  null: false
      t.string  :email, null: false
      t.text    :message, null: false
      t.boolean :read, default: false

      t.timestamps
    end

    add_index :contact_messages, :created_at
  end
end
