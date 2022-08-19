class ChangeDefaultUserName < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :name, :string, default: 'Unnamed'
    User.where(name: 'CHANGEME').update_all(name: 'Unnamed', updated_at: Time.zone.now)
  end
end
