# We're only going to have a contact name for product drive participants now
class DeleteNameFromDiaperDriveParticipants < ActiveRecord::Migration[5.2]
  def change
    change_table :diaper_drive_participants do |t|
      t.remove :contact_name
      t.rename :name, :contact_name
    end
  end
end
