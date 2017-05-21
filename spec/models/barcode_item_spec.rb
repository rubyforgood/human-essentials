# == Schema Information
#
# Table name: barcode_items
#
#  id              :integer          not null, primary key
#  value           :string
#  item_id         :integer
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe BarcodeItem, type: :model do
  it "updates a counter in Item whenever it tracks a new barcode" do
    item = create(:item)
    expect { 
      create(:barcode_item, item: item)
      item.reload
    }.to change{item.barcode_items.size}.by(1)
  end

  context "Filters >" do
    it "can filter" do
      expect(subject.class).to respond_to :filter
    end

    it "->item_id shows only barcodes for a specific item_id" do
      item = create(:item)
      barcode_item = create(:barcode_item, item: item)
      create(:barcode_item)
      results = BarcodeItem.item_id(item.id)
      expect(results.length).to eq(1)
      expect(results.first).to eq(barcode_item)
    end
  end

  context "validations >" do
    it "is invalid without an organization" do
      expect(build(:barcode_item, organization: nil)).not_to be_valid
    end
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

  describe "to_line_item >" do
    it "emits a hash for a line_item" do
      barcode_item = create :barcode_item
      expect(barcode_item.to_line_item).to eq({item_id: barcode_item.item_id, quantity: barcode_item.quantity})
    end
  end
end
