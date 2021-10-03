# capture which partner user created the request
class AddPartnerUserIdToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :partner_user_id, :integer, default: nil
  end
end
