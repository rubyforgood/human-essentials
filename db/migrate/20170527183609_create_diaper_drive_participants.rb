# The Stakeholder wanted to track DiaperDrive Participants
class CreateDiaperDriveParticipants < ActiveRecord::Migration[5.0]
  def change
    create_table :diaper_drive_participants do |t|
      t.string :name
      t.string :contact_name
      t.string :email
      t.string :phone
      t.string :comment
      t.integer :organization_id

      t.timestamps
    end
  end
end
