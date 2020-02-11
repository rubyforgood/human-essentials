class AddDiaperDriveIdToDonations < ActiveRecord::Migration[5.2]
  def change
    add_reference :donations, :diaper_drive, foreign_key: true
  end
end
