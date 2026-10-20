# Diaper and period supply banks from the NDBN member directory and the Alliance for Period
# Supplies' allied programs, for the public bank finder. Replaced wholesale by
# BankListingImportService every week; not scoped to an organization, because these are not
# Human Essentials customers. See ADR 0014.
class CreateBankListings < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_listings do |t|
      t.string :name, null: false
      t.string :name_key, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :website
      t.boolean :diapers, null: false, default: false
      t.boolean :period_supplies, null: false, default: false
      t.integer :ndbn_member_id
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
    add_index :bank_listings, :name_key, unique: true
  end
end
