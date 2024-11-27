# Getting the daily version as we monitor the difference between inventory in/out and inventory problem.
# Use -- bring down a local copy of production,  then rake create_inventory_in_out_daily_view
#     -- sum the differences, then compare to previous pull.   If the sum of differences has changed
#     -- then there has been "inventory drift" in the non-kit items since the last pull
#     -- This was meant to be a daily pull, but has been paused while some known issues are addressed.
require 'csv'
task :create_inventory_in_out_daily_view => :environment do
  # Create a big ol' report that is the inventory levels of all the items on all the storage locations.
  # Let's organize it by organization

  headers = ["Organization ID","Organization Name", "Storage Location ID", "Storage Location Name", "Item ID", "Item Name", "Inventory In", "Inventory Out", "Expected", "Current Inventory", "Diff", "Inventory item created", "Inventory Item  last updated"]

  file = "#{Rails.root}/public/inventory_check_#{Time.now}.csv"
  CSV.open(file, 'w', write_headers: true, headers:headers) do |writer|
    organizations = Organization.alphabetized
    organizations.each do |org|
      puts "#{org.id}, #{org.name}"
      storage_locations = org.storage_locations.active_locations.order(:name)
      storage_locations.each do |loc|
        puts "#{org.id}, #{org.name}, #{loc.id}, #{loc.name}"
        line_items_in = ItemsInQuery.new(organization: org, storage_location: loc).call
        line_items_out = ItemsOutQuery.new(organization: org, storage_location: loc).call
        inventory = loc.inventory_items
        line_items_in.each do |line_in|
          in_item_id = line_in.item_id
          in_quantity = line_in.quantity
          line_out = line_items_out.where(item_id: in_item_id).first
          if(line_out.nil?)
            out_quantity = 0
          else
            out_quantity = line_out.quantity
          end
          expected = in_quantity - out_quantity
          inventory_item = inventory.where(item_id: in_item_id).first
          if inventory_item.nil?
            inventory_quantity = 0
            difference = expected - inventory_quantity
            writer << [org.id, org.name,  loc.id, loc.name, in_item_id, line_in.item.name, in_quantity, out_quantity, expected, inventory_quantity, difference, "N/A","N/A"]
          else
            inventory_quantity = inventory_item.quantity
            difference = expected - inventory_quantity
            writer << [org.id, org.name,  loc.id, loc.name, in_item_id, line_in.item.name, in_quantity, out_quantity, expected, inventory_quantity, difference, inventory_item.created_at, inventory_item.updated_at]
          end


          #   puts "#{org.id}, #{org.name}, #{loc.id}, #{loc.name}, #{in_item_id}, #{line_in.item.name}, #{in_quantity},#{out_quantity}, #{expected}, #{inventory_quantity},#{difference}"

        end

      end
    end

  end

end