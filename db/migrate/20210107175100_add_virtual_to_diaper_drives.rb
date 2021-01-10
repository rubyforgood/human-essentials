# Organizations can remind Partners when their deadlines are for putting in their requests
class AddVirtualToDiaperDrives < ActiveRecord::Migration[5.2]
  def change
    change_table :diaper_drives do |t|
      t.boolean :virtual, default: false, null: false
    end
  end
end
