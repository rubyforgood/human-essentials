class AddLastRoleFkToUsers < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :users, :users_roles, column: :last_role_id, validate: false, on_delete: :nullify
  end
end
