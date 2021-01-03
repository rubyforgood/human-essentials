# Organizations can remind Partners when their deadlines are for putting in their requests
class AddSquareFootageAndWarehouseTypeToStorageLocations < ActiveRecord::Migration[5.2]
  def change
    change_table :storage_locations, bulk: true do |t|
      t.integer :square_footage
      t.string :warehouse_type
    end
  end
end
