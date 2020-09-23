class CreateKits < ActiveRecord::Migration[6.0]
  def change
    create_table :kits do |t|
      t.string :name
      t.integer :storage_location_id
      t.integer :organization_id

      t.timestamps
    end
    add_index :kits, :storage_location_id
    add_index :kits, :organization_id
  end
end
