class RenameGuardianCountryToGuardianCounty < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :families, :guardian_country, :guardian_county
    }
  end
end
