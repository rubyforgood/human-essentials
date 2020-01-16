class AddDistributionLocationToOrganizations < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :distribution_location, :integer
  end
end
