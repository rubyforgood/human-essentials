class AddNoSocialMediaPresenceToPartnerProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :partner_profiles, :no_social_media_presence, :boolean
  end
end
