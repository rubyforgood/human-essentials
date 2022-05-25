class AddValidateNDBNMembershipIdToOrganizationsFk < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :organizations, :ndbn_members
  end
end
