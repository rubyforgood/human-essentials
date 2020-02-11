# Some users are more equal than others
class AddOrganizationAdminToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :organization_admin, :boolean
  end
end
