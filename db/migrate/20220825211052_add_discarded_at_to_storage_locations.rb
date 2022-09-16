class AddDiscardedAtToStorageLocations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :storage_locations, :discarded_at, :datetime
    add_index :storage_locations, :discarded_at, algorithm: :concurrently
  end
end
