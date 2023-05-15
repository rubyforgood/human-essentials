class RenameServedAreasToPartnerServedAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :partner_served_areas do |t|
      t.references :partner_profile, null: false, foreign_key: true
      t.references :county, null: false, foreign_key: true
      t.integer :client_share
      t.timestamps
    end
    drop_table :served_areas do |t|
      t.references :partner_profile, null: false, foreign_key: true
      t.references :county, null: false, foreign_key: true
      t.integer :client_share
      t.timestamps
    end
  end
end
