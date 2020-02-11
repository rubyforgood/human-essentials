# Stakeholder request
class AddLastRequestAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_request_at, :datetime
  end
end
