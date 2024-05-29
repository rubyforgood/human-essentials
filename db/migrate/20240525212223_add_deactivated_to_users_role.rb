class AddDeactivatedToUsersRole < ActiveRecord::Migration[7.1]
  def up
    add_column :users_roles, :deactivated, :boolean
    change_column_default :users_roles, :deactivated, false
  end

  def down
    remove_column :users_roles, :deactivated
  end
end
