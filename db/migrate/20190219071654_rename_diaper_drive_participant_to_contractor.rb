class RenameDiaperDriveParticipantToContractor < ActiveRecord::Migration[5.2]
  def change
    rename_table :diaper_drive_participants, :contractors
    add_column :contractors, :type, :string, default: 'DiaperDriveParticipant'
  end
end
