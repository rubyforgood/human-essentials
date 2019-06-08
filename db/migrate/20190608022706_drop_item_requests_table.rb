class DropItemRequestsTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :item_requests, if_exists: true
  end

  def down
  end
end
