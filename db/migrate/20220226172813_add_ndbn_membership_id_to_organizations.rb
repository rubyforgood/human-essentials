class AddNDBNMembershipIdToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :ndbn_member_id, :bigint
    add_foreign_key :organizations, :ndbn_members, primary_key: :ndbn_member_id, validate: false
  end
end


