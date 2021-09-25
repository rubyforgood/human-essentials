# capture which partner user created the partner request
class AddPartnerUserIdToPartnerRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :partner_requests, :partner_user_id, :integer, null: true, default: nil
  end
end
