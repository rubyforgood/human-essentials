class AddVisibleToPartnersToKits < ActiveRecord::Migration[6.0]
  def change
    add_column :kits, :visible_to_partners, :boolean, default: true, null: false
  end
end
