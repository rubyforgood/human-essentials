class AddQuantityPickedUpToChildItemRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :child_item_requests, :quantity_picked_up, :integer
  end
end
