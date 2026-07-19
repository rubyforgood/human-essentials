class AddInfoForPartnerToPartner < ActiveRecord::Migration[8.0]
  def change
    add_column :partners, :info_for_partner, :text
  end
end
