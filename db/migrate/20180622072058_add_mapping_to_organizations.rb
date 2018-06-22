class AddMappingToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :latitude, :float
    add_column :organizations, :longitude, :float
  end
end
