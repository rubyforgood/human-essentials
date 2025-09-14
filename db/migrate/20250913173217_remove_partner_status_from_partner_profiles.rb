class RemovePartnerStatusFromPartnerProfiles < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :partner_profiles, :partner_status, :string }
  end
end
