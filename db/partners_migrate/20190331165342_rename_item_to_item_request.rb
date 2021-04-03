class RenameItemToItemRequest < ActiveRecord::Migration[5.2]
  def change
    rename_table :items, :item_requests
    add_column :item_requests, :partner_key, :string
    add_column :item_requests, :item_id, :integer
    add_index :item_requests, :item_id
  end
end
