class AddJoinTableBetweenPartnerGroupsToItemCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :partner_groups_item_categories do |t|
      t.references :partner, foreign_key: true
      t.references :item_categories, foreign_key: true

      t.timestamps
    end
  end
end
