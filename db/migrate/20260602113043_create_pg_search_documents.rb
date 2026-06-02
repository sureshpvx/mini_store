class CreatePgSearchDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :pg_search_documents do |t|
      t.text :content
      t.references :searchable, polymorphic: true, null: false, index: true
      t.timestamps
    end
  end
end