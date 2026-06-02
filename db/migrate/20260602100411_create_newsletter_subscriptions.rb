class CreateNewsletterSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletter_subscriptions do |t|
      t.string :email, null: false
      t.boolean :subscribed, default: true

      t.timestamps
    end
    add_index :newsletter_subscriptions, :email, unique: true
  end
end
