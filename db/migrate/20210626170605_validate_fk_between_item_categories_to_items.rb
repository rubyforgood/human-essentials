class ValidateFkBetweenItemCategoriesToItems < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :items, :item_categories
  end
end
