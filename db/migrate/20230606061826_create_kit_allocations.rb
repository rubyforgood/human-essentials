class CreateKitAllocations < ActiveRecord::Migration[7.0]
  def change
    create_table :kit_allocations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :storage_location, null: false, foreign_key: true
      t.references :kit, null: false, foreign_key: true
      t.timestamps
    end
  end
end
