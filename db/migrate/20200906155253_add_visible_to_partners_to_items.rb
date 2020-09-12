class AddVisibleToPartnersToItems < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :visible_to_partners, :boolean, default: true, null: false
  end
end
