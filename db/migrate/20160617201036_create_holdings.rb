# Creates the initial "holdings" table, these are later renamed to "InventoryItems"
class CreateHoldings < ActiveRecord::Migration[5.0]
  def change
    create_table :holdings do |t|
      t.integer :inventory_id
      t.integer :item_id
      t.integer :quantity

      t.timestamps
    end
  end
end
