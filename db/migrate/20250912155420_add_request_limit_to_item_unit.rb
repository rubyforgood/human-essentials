class AddRequestLimitToItemUnit < ActiveRecord::Migration[8.0]
  def change
    add_column :item_units, :request_limit, :integer, default: nil, null: true
    add_column :items, :unit_request_limit, :integer, default: nil, null: true
  end
end
