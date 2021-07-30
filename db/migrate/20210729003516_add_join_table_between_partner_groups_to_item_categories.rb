class AddJoinTableBetweenPartnerGroupsToItemCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :item_categories_partner_groups do |t|
      t.references :partner_group, foreign_key: true, null: false
      t.references :item_category, foreign_key: true, null: false

      t.timestamps
    end
  end
end
