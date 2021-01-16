class CreatePartnerGroupItems < ActiveRecord::Migration[6.0]
  def change
    create_table :partner_group_items do |t|
      t.references :partner_group, foreign_key: true, null: false
      t.references :item, foreign_key: true, null: false

      t.timestamps
    end
  end
end
