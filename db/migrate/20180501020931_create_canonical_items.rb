class CreateCanonicalItems < ActiveRecord::Migration[5.1]
  def change
    create_table :canonical_items do |t|
      t.string :key
      t.string :name
      t.integer :barcode_count

      t.timestamps
    end
  end
end
