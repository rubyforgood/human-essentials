class AddAddressToDiaperDriveParticipants < ActiveRecord::Migration[5.1]
  def change
    add_column :diaper_drive_participants, :address, :string
  end
end
