class ChangeDropoffLocationToDonationSite < ActiveRecord::Migration[5.1]
  def up
    remove_index :donations, :dropoff_location_id
    remove_index :dropoff_locations, :organization_id
    
    rename_table :dropoff_locations, :donation_sites
    rename_column :donations, :dropoff_location_id, :donation_site_id

    add_index :donations, :donation_site_id, :name => "index_donations_on_donation_site_id"
    add_index :donation_sites, :organization_id, :name => "index_donation_sites_on_organization_id"
  end

  def down
    remove_index :donations, :donation_site_id
    remove_index :donation_sites, :organization_id
    
    rename_table :donation_sites, :dropoff_locations
    rename_column :donations, :donation_site_id, :dropoff_location_id

    add_index :donations, :dropoff_location_id, :name => "index_donations_on_dropoff_location_id"
    add_index :dropoff_locations, :organization_id, :name => "index_dropoff_locations_on_organization_id"
  end
end
