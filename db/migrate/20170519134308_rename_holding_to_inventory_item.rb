# We wanted a name that made the similar behavior more clear between LineItems and StorageItems
class RenameHoldingToInventoryItem < ActiveRecord::Migration[5.0]
  def change
    rename_table :holdings, :inventory_items
  end
end
