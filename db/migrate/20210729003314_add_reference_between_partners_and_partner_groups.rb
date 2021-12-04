class AddReferenceBetweenPartnersAndPartnerGroups < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :partners, :partner_group, index: { algorithm: :concurrently }
  end
end
