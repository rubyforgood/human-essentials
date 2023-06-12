class AddKitAllocationTypeToKitAllocations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_enum :kit_allocation_inventory, ["inventory_in", "inventory_out"]
      change_table :kit_allocations do |t|
        t.enum :inventory, enum_type: "kit_allocation_inventory", default: "inventory_in", null: false
      end
    end
  end
end
