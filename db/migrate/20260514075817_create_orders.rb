class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :total_price, precision: 10, scale: 2, default: 0

      t.integer :status, default: 0, null: false

      t.integer :payment_status, default: 0, null: false

      t.timestamps
    end
  end
end
