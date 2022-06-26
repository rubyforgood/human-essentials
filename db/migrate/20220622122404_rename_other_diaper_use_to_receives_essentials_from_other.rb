class RenameOtherDiaperUseToReceivesEssentialsFromOther < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :partner_profiles, :other_diaper_use, :receives_essentials_from_other
    }
  end
end
