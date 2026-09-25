class RemoveKitsTableAndItemsKitId < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      drop_table :kit_allocations if table_exists?(:kit_allocations)
      drop_enum :kit_allocation_type, if_exists: true
      remove_foreign_key :items, :kits if foreign_key_exists?(:items, :kits)
      remove_column :items, :kit_id, :integer if column_exists?(:items, :kit_id)
      drop_table :kits if table_exists?(:kits)
    end
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
