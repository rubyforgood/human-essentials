# Helps avoid pesky nil errors
class DefaultInventoryQuantityToZero < ActiveRecord::Migration[5.2]
  def change
    change_column :inventory_items, :quantity, :integer, default: 0
  end
end
