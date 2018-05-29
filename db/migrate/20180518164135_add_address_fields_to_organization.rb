class AddAddressFieldsToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :street, :string
    add_column :organizations, :city, :string
    add_column :organizations, :state, :string
    add_column :organizations, :zipcode, :string
    remove_column :organizations, :address
  end
end
