class AddPickedUpToChildItemRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :child_item_requests, :picked_up, :boolean, default: false
  end
end
