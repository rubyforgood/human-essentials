class CreatePartnerCounties < ActiveRecord::Migration[7.0]
  def change
    create_table :partner_counties do |t|
      t.references :partner, null: false, foreign_key: true
      t.references :county, null: false, foreign_key: true
      t.integer :client_share

      t.timestamps
    end
  end
end
