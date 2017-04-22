class CreateDropoffLocations < ActiveRecord::Migration
  def change
    create_table :dropoff_locations do |t|
    	t.string :name
    	t.string :address
      t.timestamps
    end
  end
end
