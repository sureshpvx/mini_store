class AddShippingFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_full_name, :string
    add_column :orders, :shipping_phone_number, :string

    add_column :orders, :shipping_address_line_1, :string
    add_column :orders, :shipping_address_line_2, :string

    add_column :orders, :shipping_city, :string
    add_column :orders, :shipping_state, :string
    add_column :orders, :shipping_postal_code, :string
    add_column :orders, :shipping_country, :string
  end
end
