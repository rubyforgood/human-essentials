class AddNDBNMembershipIdToAccountRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :account_requests, :ndbn_member_id, :bigint
    add_foreign_key :account_requests, :ndbn_members, primary_key: :ndbn_member_id, validate: false
  end
end
