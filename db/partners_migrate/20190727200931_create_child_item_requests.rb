class CreateChildItemRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :child_item_requests do |t|
      t.references :child, index: true, foreign_key: true
      t.references :item_request, index: true, foreign_key: true
      t.timestamps
    end
  end
end
