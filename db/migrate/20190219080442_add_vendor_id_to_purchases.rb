# Connect Vendors to Purchases
class AddVendorIdToPurchases < ActiveRecord::Migration[5.2]
  def change
    add_column :purchases, :vendor_id, :integer
  end
end
