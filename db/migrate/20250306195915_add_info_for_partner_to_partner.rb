class AddInfoForPartnerToPartner < ActiveRecord::Migration[7.2]
  def change
    add_column :partners, :info_for_partner, :string
  end
end
