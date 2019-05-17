# Calling them "Canonical Items" was a terrible idea. The concept was solid, though.
# These are later renamed "BaseItems", and are a means for allowing the Diaperbanks to
# customize the item types they track, while still giving us a common language to use
# when providing stats
class CreateCanonicalItems < ActiveRecord::Migration[5.1]
  def change
    create_table :canonical_items do |t|
      t.string :key
      t.string :name
      t.string :category
      t.integer :barcode_count

      t.timestamps
    end
  end
end
