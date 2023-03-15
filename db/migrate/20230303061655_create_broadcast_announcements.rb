class CreateBroadcastAnnouncements < ActiveRecord::Migration[7.0]
  def change
    create_table :broadcast_announcements do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, :limit => 500
      t.text :link
      t.date :expiry

      t.timestamps
    end
  end
end
