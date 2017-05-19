class AddOrganizationIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :organization_id, :integer
  end
end
