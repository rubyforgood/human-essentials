# Fix to ensure that the object is available in the migration
class BarcodeItem < ApplicationRecord; end

# Remove the global field -- we're no longer using this.
class RemoveGlobalFromBarcodeItem < ActiveRecord::Migration[5.2]
  def up
    remove_column :barcode_items, :global
  end

  def down
    add_column :barcode_items, :global, :boolean, default: false
    global_barcodes = BarcodeItem.where(barcodeable_type: "BaseItem")
    puts "Setting global field for #{global_barcodes.size} barcodes..."
    global_barcodes.update_all(global: true)
  end
end
