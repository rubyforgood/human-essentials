class AddRejectionReasonToAccountRequests < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_column :account_requests, :rejection_reason, :string
    add_column :account_requests, :status, :string, default: 'started', null: false
    add_index :account_requests, :status, algorithm: :concurrently

    AccountRequest.joins(:organization).where.not(confirmed_at: nil).
      update_all(status: 'admin_approved', updated_at: Time.zone.now)

    # could do a left join plus null check on organization_id, but this way is quicker since
    # it relies on the fact that any confirmed request that *hasn't* been updated in the previous query
    # must not have an organization.
    AccountRequest.where.not(confirmed_at: nil).where(status: 'started').
      update_all(status: 'user_confirmed', updated_at: Time.zone.now)

    # If confirmed is nil then we leave it as started.
  end

  def down
    remove_column :account_requests, :rejection_reason
    remove_column :account_requests, :status, :string
  end

end
