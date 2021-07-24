class AddLineItemsTotalToPurchases < ActiveRecord::Migration[6.1]
  def self.up
    add_column :purchases, :line_items_total, :integer, null: false, default: 0
  end

  def self.down
    remove_column :purchases, :line_items_total
  end
end
