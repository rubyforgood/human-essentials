# Make Geocode lookups faster
class AddIndicesToGeocodables < ActiveRecord::Migration[5.2]
  def change
    add_index :organizations, [:latitude, :longitude]
    add_index :diaper_drive_participants, [:latitude, :longitude]
    add_index :storage_locations, [:latitude, :longitude]
    add_index :donation_sites, [:latitude, :longitude]
  end
end
