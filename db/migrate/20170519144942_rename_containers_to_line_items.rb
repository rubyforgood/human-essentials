class RenameContainersToLineItems < ActiveRecord::Migration[5.0]
  def change
    rename_table :containers, :line_items
  end
end
