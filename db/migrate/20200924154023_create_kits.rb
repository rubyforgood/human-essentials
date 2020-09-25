class CreateKits < ActiveRecord::Migration[6.0]
  def change
    create_table :kits do |t|
      t.string :name
      t.integer :organization_id

      t.timestamps
    end
    add_index :kits, :organization_id
  end
end
