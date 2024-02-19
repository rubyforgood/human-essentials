class CreateNeededItem < ActiveRecord::Migration[7.0]
  def change
    create_table :needed_items do |t|
      t.integer :child_id, null: false, index: true
      t.integer :item_id, null: false, index: true
      t.timestamps
    end
  end
end
