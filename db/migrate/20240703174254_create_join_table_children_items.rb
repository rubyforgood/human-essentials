class CreateJoinTableChildrenItems < ActiveRecord::Migration[7.1]
  def change
    create_join_table :children, :items do |t|
      t.index [:child_id, :item_id], unique: true
      t.index [:item_id, :child_id], unique: true
    end
  end
end
