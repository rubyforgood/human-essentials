def initialize_barcodes
  # create one pre-existing barcode associated with an item
  @existing_barcode = create(:barcode_item)
  @item_with_barcode = @existing_barcode.item
  # create a new item that has no barcode existing for it yet
  @item_no_barcode = create(:item)
end
