class CreateKitItems < ActiveRecord::Migration[6.0]
  def change
    create_table :kit_items do |t|
      t.integer :item_id
      t.integer :kit_id
      t.integer :quantity

      t.timestamps
    end
    add_index :kit_items, :item_id
    add_index :kit_items, :kit_id
  end
end
