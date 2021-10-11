class AddFkBetweenItemCategoriesAndOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :item_categories, :organizations, validate: false
  end
end
