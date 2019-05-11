# This was later renamed something else
class AddIntakeLocationToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :intake_location, :integer
  end
end
