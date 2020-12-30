class CreatePartnerGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :partner_groups do |t|
      t.references :organization, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
