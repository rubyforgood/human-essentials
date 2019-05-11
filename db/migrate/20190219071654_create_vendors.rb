# Initial table for Vendors
class CreateVendors < ActiveRecord::Migration[5.2]
  def change
    create_table :vendors do |t|
      t.string :contact_name
      t.string :email
      t.string :phone
      t.string :comment
      t.integer :organization_id
      t.string :address
      t.string :business_name
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
    add_index :vendors, [:latitude, :longitude]
  end
end
