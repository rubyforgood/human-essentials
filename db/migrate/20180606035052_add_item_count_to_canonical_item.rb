# Now we can track how many items are under each canonical item
class AddItemCountToCanonicalItem < ActiveRecord::Migration[5.2]
  def change
    add_column :canonical_items, :item_count, :integer
  end
end
