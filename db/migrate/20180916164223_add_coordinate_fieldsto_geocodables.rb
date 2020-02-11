# Enable Geocoding for resources with addresses
class AddCoordinateFieldstoGeocodables < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :latitude, :float
    add_column :organizations, :longitude, :float
    add_column :diaper_drive_participants, :latitude, :float
    add_column :diaper_drive_participants, :longitude, :float
    add_column :donation_sites, :latitude, :float
    add_column :donation_sites, :longitude, :float
    add_column :storage_locations, :latitude, :float
    add_column :storage_locations, :longitude, :float
  end
end
