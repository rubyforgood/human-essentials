class ValidateLastRoleFk < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :users, :users_roles, column: :last_role_id
  end
end
