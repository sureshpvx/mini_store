class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.references :parent, null: true, foreign_key: { to_table: :categories }

      t.timestamps
    end

    # Optional but recommended
    add_index :categories, :name
  end
end