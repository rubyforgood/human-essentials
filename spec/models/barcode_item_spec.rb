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
  it "updates a counter in Item whenever it tracks a new barcode" do
    item = create(:item)
    expect { 
      create(:barcode_item, item: item)
      item.reload
    }.to change{item.barcode_items.size}.by(1)
  end

  context "validations >" do
    describe "value >" do
      it "requires a value" do
        expect(build(:barcode_item, value: nil)).not_to be_valid
      end
      it "enforces uniqueness in barcode value" do
        barcode_item = create(:barcode_item)
        expect(build(:barcode_item, value: barcode_item.value)).not_to be_valid
      end
    end

    describe "item >" do
      it "is invalid without an item associated with it" do
        expect(build(:barcode_item, item: nil)).not_to be_valid
      end
    end

    describe "quantity >" do
      it "is not nil" do
        expect(build(:barcode_item, quantity: nil)).not_to be_valid
      end
      it "is an integer" do
        expect(build(:barcode_item, quantity: 'aaa')).not_to be_valid
      end
      it "is not a negative number" do
        expect(build(:barcode_item, quantity: -1)).not_to be_valid
      end  
    end
  end

  describe "to_container >" do
    it "emits a hash for a container" do
      barcode_item = create :barcode_item
      expect(barcode_item.to_container).to eq({item_id: barcode_item.item_id, quantity: barcode_item.quantity})
    end
  end
end