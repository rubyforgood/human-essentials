class AddTimeZoneToStorageLocations < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :storage_locations, :time_zone, :string, null: false, default: 'America/Los_Angeles'
    end
  end
end
