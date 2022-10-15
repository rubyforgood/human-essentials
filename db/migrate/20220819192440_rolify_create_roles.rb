class RolifyCreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table(:roles) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:users_roles) do |t|
      t.references :user
      t.references :role
    end

    add_index(:roles, [ :name, :resource_type, :resource_id ])
    add_index(:users_roles, [ :user_id, :role_id ])
  end
end
