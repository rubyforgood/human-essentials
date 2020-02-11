# We realized that "Storage Location" was a more meaningful name for this resource
class RenameInventoryToStorageLocation < ActiveRecord::Migration[5.0]
  def change
    rename_table :inventories, :storage_locations
    rename_column :inventory_items, :inventory_id, :storage_location_id
    rename_column :distributions, :inventory_id, :storage_location_id
    rename_column :donations, :inventory_id, :storage_location_id
  end
end
