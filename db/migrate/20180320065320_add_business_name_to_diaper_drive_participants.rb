class AddBusinessNameToDiaperDriveParticipants < ActiveRecord::Migration[5.1]
  def change
    add_column :diaper_drive_participants, :business_name, :string
  end
end
