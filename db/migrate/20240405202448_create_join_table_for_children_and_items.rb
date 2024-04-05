class CreateJoinTableForChildrenAndItems < ActiveRecord::Migration[7.0]
  def change
    create_join_table :child, :items do |t|
      t.index [:child_id, :item_id]
      t.index [:item_id, :child_id]
    end
  end
end
