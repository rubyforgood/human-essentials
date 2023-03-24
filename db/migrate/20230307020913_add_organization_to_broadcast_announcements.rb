class AddOrganizationToBroadcastAnnouncements < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :broadcast_announcements, :organization, null: false, index: {algorithm: :concurrently}
  end
end
