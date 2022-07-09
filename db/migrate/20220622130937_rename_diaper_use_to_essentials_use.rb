class RenameDiaperUseToEssentialsUse < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :partner_profiles, :diaper_use, :essentials_use
    }
  end
end
