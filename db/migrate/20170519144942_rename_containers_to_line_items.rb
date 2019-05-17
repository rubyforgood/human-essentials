# We wanted to have a name that was was more similar to the one used for StorageLocations,
# since they both function very similarly, even though their roles are slightly different.
class RenameContainersToLineItems < ActiveRecord::Migration[5.0]
  def change
    rename_table :containers, :line_items
  end
end
