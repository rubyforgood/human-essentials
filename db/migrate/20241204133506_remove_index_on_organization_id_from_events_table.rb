class RemoveIndexOnOrganizationIdFromEventsTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :events, :organization_id, algorithm: :concurrently
  end
end
