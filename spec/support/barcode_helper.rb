module Barcode
  # The id of the one scan field on a line item card. There used to be one per row, named
  # `_barcode-lookup-<index>`, and this helper's job was to hunt for the last empty one.
  SCAN_FIELD = "line-item-scan".freeze

  # `barcode_field` is accepted and ignored. It named which row's barcode input to type into,
  # and there is only one field now, so every call site would otherwise have had to drop an
  # argument that no longer means anything.
  def self.boop(value, _barcode_field = nil)
    Capybara.find(id: SCAN_FIELD).click
    Capybara.page.driver.browser.keyboard.type(value + "\n")
  end
end

def initialize_barcodes
  # create one pre-existing barcode associated with an item
  @existing_barcode = create(:barcode_item)
  @item_with_barcode = @existing_barcode.item
  # create a new item that has no barcode existing for it yet
  @item_no_barcode = create(:item)
end
