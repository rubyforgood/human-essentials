class AddInstagramToPartnerProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :partner_profiles, :instagram, :string
  end
end
