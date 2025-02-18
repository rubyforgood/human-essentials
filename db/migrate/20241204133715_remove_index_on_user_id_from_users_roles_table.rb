class RemoveIndexOnUserIdFromUsersRolesTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :users_roles, :user_id, algorithm: :concurrently
  end
end
