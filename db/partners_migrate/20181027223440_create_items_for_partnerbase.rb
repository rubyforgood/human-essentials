class CreateItemsForPartnerbase < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :name
      t.string :quantity
      t.belongs_to :partner_request, foreign_key: true

      t.timestamps
    end
  end
end
