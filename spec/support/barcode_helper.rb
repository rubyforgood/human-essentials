module Barcode
  def self.boop(value, barcode_field = nil)
    barcode_field ||= get_last_empty_barcode_field
    Capybara.find(id: "_barcode-lookup-" + barcode_field.to_s).click
    Capybara.page.driver.browser.keyboard.type(value + "\n")
  end

  def self.get_last_empty_barcode_field
    last_empty_field = 0
    last_empty_field += 1 until is_empty?(last_empty_field)
    last_empty_field
  end

  def self.is_empty?(field)
    Capybara.find("#_barcode-lookup-" + field.to_s).value == ""
  rescue Capybara::ElementNotFound
    false
  end
end

def initialize_barcodes
  # create one pre-existing barcode associated with an item
  @existing_barcode = create(:barcode_item)
  @item_with_barcode = @existing_barcode.item
  # create a new item that has no barcode existing for it yet
  @item_no_barcode = create(:item)
end
