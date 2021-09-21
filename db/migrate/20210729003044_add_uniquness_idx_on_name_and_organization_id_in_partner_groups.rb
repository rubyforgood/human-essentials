class AddUniqunessIdxOnNameAndOrganizationIdInPartnerGroups < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :partner_groups, [:name, :organization_id], unique: true, algorithm: :concurrently
  end
end
