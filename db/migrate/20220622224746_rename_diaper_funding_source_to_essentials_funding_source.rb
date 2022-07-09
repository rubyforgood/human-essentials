class RenameDiaperFundingSourceToEssentialsFundingSource < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :partner_profiles, :diaper_funding_source, :essentials_funding_source
    }
  end
end
