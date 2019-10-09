class BarcodeItemsSeeder
  ITEMS = [
    { value: "10037867880046", name: "Kids (Size 5)", quantity: 108 },
    { value: "10037867880053", name: "Kids (Size 6)", quantity: 92 },
    { value: "10037867880039", name: "Kids (Size 4)", quantity: 124 },
    { value: "803516626364", name: "Kids (Size 1)", quantity: 40 },
    { value: "036000406535", name: "Kids (Size 1)", quantity: 44 },
    { value: "037000863427", name: "Kids (Size 1)", quantity: 35 },
    { value: "041260379000", name: "Kids (Size 3)", quantity: 160 },
    { value: "074887711700", name: "Wipes (Baby)", quantity: 8 },
    { value: "036000451306", name: "Kids Pull-Ups (4T-5T)", quantity: 56 },
    { value: "037000862246", name: "Kids (Size 4)", quantity: 92 },
    { value: "041260370236", name: "Kids (Size 4)", quantity: 68 },
    { value: "036000407679", name: "Kids (Size 4)", quantity: 24 },
    { value: "311917152226", name: "Kids (Size 4)", quantity: 82 },
  ].freeze

  def self.seed(org)
    ITEMS.each do |item|
      BarcodeItem.find_or_create_by!(value: item[:value]) do |barcode|
        barcode.item = Item.find_by(name: item[:name])
        barcode.quantity = item[:quantity]
        barcode.organization = org
      end
    end
  end
end
