class AddLastRoleIdToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :users, :last_role, null: true, index: {algorithm: :concurrently}
  end
end
