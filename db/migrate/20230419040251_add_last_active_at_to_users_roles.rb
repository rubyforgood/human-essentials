class AddLastActiveAtToUsersRoles < ActiveRecord::Migration[7.0]
  def up
    add_column :users_roles, :last_active_at, :timestamp, if_not_exists: true
  end

  def down
    remove_column :users_roles, :last_active_at, if_exists: true
  end
end
