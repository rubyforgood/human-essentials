class RenameAgencyGuardianIdToCaseManager < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :families, :agency_guardian_id, :case_manager
    }
  end
end
