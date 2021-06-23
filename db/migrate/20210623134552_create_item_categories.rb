class CreateItemCategories < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    create_table :item_categories do |t|
      t.string :name, nil: false
      t.text :description
      t.integer :organization_id, null: false

      t.timestamps
    end

    add_index :item_categories, [:name, :organization_id], unique: true
  end
end
