# Some barcodes are available to everyone
class AddGlobalToBarcodeItem < ActiveRecord::Migration[5.1]
  def change
    add_column :barcode_items, :global, :boolean, default: false
  end
end
