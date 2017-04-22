# == Schema Information
#
# Table name: barcode_items
#
#  id         :integer          not null, primary key
#  value      :string
#  item_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  quantity   :integer
#

require 'rails_helper'

RSpec.describe BarcodeItem, type: :model do
  describe "value" do
    it "is not nil" do
      barcode_item = build(:barcode_item, value: nil)
      expect(barcode_item).not_to be_valid
    end
    it "has a unique barcode string value" do
      barcode_item = create :barcode_item
      bad_barcode = build(:barcode_item, value: barcode_item.value)
      expect(bad_barcode).not_to be_valid
    end
  end
  it "is invalid without an item associated with it" do
    expect(build(:barcode_item, item: nil)).not_to be_valid
  end
  describe "quantity" do
    it "is not nil" do
      barcode_item = build(:barcode_item, quantity: nil)
      expect(barcode_item).not_to be_valid
    end
    it "is an integer" do
      barcode_item = build(:barcode_item, quantity: 'aaa')
      expect(barcode_item).not_to be_valid
    end
    it "is not a negative number" do
      barcode_item = build(:barcode_item, quantity: -1)
      expect(barcode_item).not_to be_valid
    end
  end
  it "emits a hash for a container" do
    barcode_item = create :barcode_item
    expect(barcode_item.to_container).to eq({item_id: barcode_item.item_id, quantity: barcode_item.quantity})
  end
end
