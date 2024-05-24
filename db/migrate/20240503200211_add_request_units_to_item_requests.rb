class AddRequestUnitsToItemRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :item_requests, :request_unit, :string
  end
end
