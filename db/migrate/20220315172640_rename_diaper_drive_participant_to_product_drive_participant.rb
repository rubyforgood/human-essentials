class RenameDiaperDriveParticipantToProductDriveParticipant < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
       rename_table :diaper_drive_participants, :product_drive_participants
       rename_column :donations, :diaper_drive_participant_id, :product_drive_participant_id

    }

  end
end
