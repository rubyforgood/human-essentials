# Add active column to vendors to make it possible to delete vendors without actually deleting them
class SetExistingVendorsActive < ActiveRecord::Migration[7.2]
  def change
    Vendor.update_all(active: true)
  end
end
