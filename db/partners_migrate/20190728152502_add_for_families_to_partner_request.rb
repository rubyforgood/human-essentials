class AddForFamiliesToPartnerRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :partner_requests, :for_families, :boolean
  end
end
