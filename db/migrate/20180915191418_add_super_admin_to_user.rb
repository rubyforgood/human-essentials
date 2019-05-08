# Some users are EVEN MORE equal than others
class AddSuperAdminToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :super_admin, :boolean, default: false
  end
end
