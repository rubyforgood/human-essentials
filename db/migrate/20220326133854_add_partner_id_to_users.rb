class AddPartnerIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :partner_id, :integer
  end
end
