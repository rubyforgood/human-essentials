class AddItemCategoryIdToItem < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :item_category_id, :integer, index: true
  end
end
