# capture which partner user created the partner request
class AddPartnerUserIdToPartnerRequests < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :partner_requests, :partner_user_id, :integer, default: nil
      add_foreign_key :partner_requests, :users, column: :partner_user_id, primary_key: :id
    end
  end
end
