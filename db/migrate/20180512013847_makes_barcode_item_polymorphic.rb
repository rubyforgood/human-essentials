# Barcode items need to be able to be attached to either BaseItems or regular Items
class MakesBarcodeItemPolymorphic < ActiveRecord::Migration[5.1]
  def up
  	change_table :barcode_items do |t|
  		t.column :barcodeable_type, :string, default: "Item"
  		t.rename :item_id, :barcodeable_id
  	end
  	add_index :barcode_items, [:barcodeable_type, :barcodeable_id]
  end

  def down
  	remove_index :barcode_items, column: [:barcodeable_type, :barcodeable_id]
  	change_table :barcode_items do |t|
  		t.remove :barcodeable_type
  		t.rename :barcodeable_id, :item_id
  	end

  end
end
