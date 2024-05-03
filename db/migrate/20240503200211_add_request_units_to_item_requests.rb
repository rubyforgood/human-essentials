class AddRequestUnitsToItemRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :item_requests, :reporting_unit, :string
  end
end
