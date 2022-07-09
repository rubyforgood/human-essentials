class RenameDiaperBankIdToEssentialsBankId < ActiveRecord::Migration[7.0]
  def change
      safety_assured {
        rename_column :partner_forms, :diaper_bank_id, :essentials_bank_id
        rename_column :partner_profiles, :diaper_bank_id, :essentials_bank_id
        rename_index :partner_profiles, :index_partners_on_diaper_bank_id, :index_partners_on_essentials_bank_id
      }
  end
end
