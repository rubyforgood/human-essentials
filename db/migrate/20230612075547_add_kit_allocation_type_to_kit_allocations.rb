class AddKitAllocationTypeToKitAllocations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_enum :kit_allocation_type, ["inventory_in", "inventory_out"]
      if column_exists?(:kit_allocations, :kit_allocation_type)
        remove_column :kit_allocations, :kit_allocation_type
      end
      change_table :kit_allocations do |t|
        t.enum :kit_allocation_type, enum_type: "kit_allocation_type", default: "inventory_in", null: false
      end
    end
  end
end
