# Connects Items to the Requests
class CreateItemRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :item_requests do |t|
      t.references :request, foreign_key: true
      t.references :item, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
