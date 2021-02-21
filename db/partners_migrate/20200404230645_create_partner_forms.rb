class CreatePartnerForms < ActiveRecord::Migration[5.2]
  def change
    create_table :partner_forms do |t|
      t.integer :diaper_bank_id
      t.text :sections, array: true, default: []

      t.timestamps
    end
  end
end
