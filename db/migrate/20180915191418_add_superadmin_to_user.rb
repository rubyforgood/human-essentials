class AddSuperadminToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :superadmin, :boolean, default: false
  end
end
