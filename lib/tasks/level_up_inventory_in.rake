namespace :kit_allocation do
  desc "Level up inventory in to inventory out in kit_allocations"
  task inventory_in: :environment do |task|
    KitAllocation.where(kit_allocation_type: "inventory_in").destroy_all
    out_kit_allocations = KitAllocation.where(kit_allocation_type: "inventory_out")
    out_kit_allocations.each do |out_kit_allocation|
      in_kit_allocation = KitAllocation.create!(storage_location_id: out_kit_allocation.storage_location_id,
        organization_id: out_kit_allocation.organization_id,
        kit_id: out_kit_allocation.kit_id,
        kit_allocation_type: "inventory_in")
      out_kit_allocation.line_items.each do |line_item|
        in_kit_allocation.line_items.create!(item_id: line_item.item_id, quantity: line_item.quantity * -1)
      end
    end
    puts "Done..."
  end
end
