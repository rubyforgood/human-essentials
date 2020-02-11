class CreateDiaperDrives < ActiveRecord::Migration[5.2]
  def change
    create_table :diaper_drives do |t|
      t.string :name
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
