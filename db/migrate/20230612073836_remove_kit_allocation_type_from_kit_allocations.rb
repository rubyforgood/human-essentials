class RemoveKitAllocationTypeFromKitAllocations < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      remove_column :kit_allocations, :kit_allocation_type
    }
  end
end
