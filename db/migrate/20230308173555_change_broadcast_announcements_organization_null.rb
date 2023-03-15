class ChangeBroadcastAnnouncementsOrganizationNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:broadcast_announcements, :organization_id, true)
  end
end
