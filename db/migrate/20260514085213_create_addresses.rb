class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true

      t.string :full_name, null: false
      t.string :phone_number, null: false

      t.string :address_line_1, null: false
      t.string :address_line_2

      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country, null: false
      t.timestamps
    end
  end
end
