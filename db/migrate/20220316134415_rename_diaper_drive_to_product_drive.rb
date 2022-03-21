class RenameDiaperDriveToProductDrive < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      rename_table :diaper_drives, :product_drives
      rename_column :donations, :diaper_drive_id, :product_drive_id

    }
  end
end
