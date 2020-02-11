# Creates the initial "DropoffLocations" table, these are later renamed "DonationSites"
class CreateDropoffLocations < ActiveRecord::Migration[5.0]
  def change
    create_table :dropoff_locations do |t|
    	t.string :name
    	t.string :address
      t.timestamps
    end
  end
end
