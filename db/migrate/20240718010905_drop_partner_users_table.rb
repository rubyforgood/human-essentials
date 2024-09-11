class DropPartnerUsersTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :partner_users

  end
  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
