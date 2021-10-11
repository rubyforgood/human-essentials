class ValidateFkBetweenItemCategoriesAndOrganizations < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :item_categories, :organizations
  end
end
