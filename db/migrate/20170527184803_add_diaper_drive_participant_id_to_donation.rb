# Connects DiaperDriveParticipants and Donations
class AddDiaperDriveParticipantIdToDonation < ActiveRecord::Migration[5.0]
  def change
    add_column :donations, :diaper_drive_participant_id, :integer
  end
end
