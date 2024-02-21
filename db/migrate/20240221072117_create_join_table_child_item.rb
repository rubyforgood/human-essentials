class CreateJoinTableChildItem < ActiveRecord::Migration[7.0]
  def change
    create_table :children_items do |t|
      t.references :child, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true

      t.timestamps
    end

    add_index :children_items, [:child_id, :item_id], unique: true
  end
end
