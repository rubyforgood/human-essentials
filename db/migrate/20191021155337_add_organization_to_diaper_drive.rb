class AddOrganizationToDiaperDrive < ActiveRecord::Migration[6.0]
  def change
    add_reference :diaper_drives, :organization, foreign_key: true
  end
end
