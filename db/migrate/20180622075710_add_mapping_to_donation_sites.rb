class AddMappingToDonationSites < ActiveRecord::Migration[5.2]
  def change
    add_column :donation_sites, :latitude, :float
    add_column :donation_sites, :longitude, :float
  end
end
