class ChangeDefaultUserName < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :name, :string, default: 'Name Not Provided'
    User.where(name: 'CHANGEME').update_all(name: 'Name Not Provided', updated_at: Time.zone.now)
  end
end
