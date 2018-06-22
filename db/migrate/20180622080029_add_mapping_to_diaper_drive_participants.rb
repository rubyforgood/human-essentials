class AddMappingToDiaperDriveParticipants < ActiveRecord::Migration[5.2]
  def change
    add_column :diaper_drive_participants, :latitude, :float
    add_column :diaper_drive_participants, :longitude, :float
  end
end
