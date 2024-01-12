class AddStatusToPartnerRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :partner_requests, :status, :string
    add_reference :partner_requests, :bank, foreign_key: true
  end
end
