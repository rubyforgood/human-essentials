class RenameHoldingToInventoryItem < ActiveRecord::Migration[5.0]
  def change
    rename_table :holdings, :inventory_items
  end
end
