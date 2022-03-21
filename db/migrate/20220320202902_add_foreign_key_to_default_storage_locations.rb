class AddForeignKeyToDefaultStorageLocations < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :partners, :storage_locations,
                    column: :default_storage_location_id,
                    validate: false
  end
end
