class AddBankIdToPartnerRequests < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :partner_requests, :bank, null: false, index: {algorithm: :concurrently}
  end
end
