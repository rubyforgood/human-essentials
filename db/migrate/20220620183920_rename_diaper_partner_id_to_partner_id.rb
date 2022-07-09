class RenameDiaperPartnerIdToPartnerId < ActiveRecord::Migration[7.0]
  def change
    safety_assured {rename_column :partner_profiles, :diaper_partner_id, :partner_id
    }
  end
end
