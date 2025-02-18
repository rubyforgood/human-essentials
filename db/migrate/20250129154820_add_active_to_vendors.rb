# Add active column to vendors to make it possible to delete vendors without actually deleting them
class AddActiveToVendors < ActiveRecord::Migration[7.2]
  def up
    add_column :vendors, :active, :boolean
    change_column_default :vendors, :active, true
  end

  def down
    remove_column :vendors, :active
  end
end
