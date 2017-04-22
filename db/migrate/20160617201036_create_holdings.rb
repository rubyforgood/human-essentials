class CreateHoldings < ActiveRecord::Migration
  def change
    create_table :holdings do |t|
      t.integer :inventory_id
      t.integer :item_id
      t.integer :quantity

      t.timestamps
    end
  end
end
