# Connects organizations to other things
class AddsOrganizationIdToTables < ActiveRecord::Migration[5.0]
  def change
  	[:barcode_items, :distributions, :donations, :dropoff_locations, 
  	 :storage_locations, :items, :partners, :transfers].each do |t|
  	 	add_column t, :organization_id, :integer
  	 	add_index t, :organization_id
  	 end
  end
end
