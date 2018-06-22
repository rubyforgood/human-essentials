class AddMappingToStorageLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :storage_locations, :latitude, :float
    add_column :storage_locations, :longitude, :float
  end
end
