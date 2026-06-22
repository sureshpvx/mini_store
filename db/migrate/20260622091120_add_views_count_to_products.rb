class AddViewsCountToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :views_count, :integer
  end
end
