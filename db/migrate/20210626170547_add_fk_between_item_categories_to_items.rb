class AddFkBetweenItemCategoriesToItems < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :items, :item_categories, validate: false
  end
end
