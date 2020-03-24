class AddDefaultStorageLocationToOrganization < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :default_storage_location, :integer
  end
end
