class AddPickedUpItemNeededDiaperidToChildItemRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :child_item_requests, :picked_up_item_diaperid, :integer
  end
end
