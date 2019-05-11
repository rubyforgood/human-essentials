# Connects Items to CanonicalItems (later renamed BaseItems)
class AddCanonicalItemIdToItem < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :canonical_item_id, :integer
  end
end
