# == Schema Information
#
# Table name: barcode_items
#
#  id               :integer          not null, primary key
#  barcodeable_type :string           default("Item")
#  quantity         :integer
#  value            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  barcodeable_id   :integer
#  organization_id  :integer
#

RSpec.shared_examples "common barcode tests" do |barcode_item_factory|
  describe "item >" do
    it "is invalid without an item associated with it" do
      barcode = build(barcode_item_factory)
      barcode.item = nil
      expect(barcode).not_to be_valid
    end
  end

  describe "quantity >" do
    it "is not nil" do
      expect(build(barcode_item_factory, quantity: nil)).not_to be_valid
    end
    it "is an integer" do
      expect(build(barcode_item_factory, quantity: "aaa")).not_to be_valid
    end
    it "is not a negative number" do
      expect(build(barcode_item_factory, quantity: -1)).not_to be_valid
    end
  end

  describe "value >" do
    it "requires a value" do
      expect(build(barcode_item_factory, value: nil)).not_to be_valid
    end
  end
end

RSpec.describe BarcodeItem, type: :model do
  context "Organization barcodes" do
    let(:item) { create(:item) }
    let(:barcode_item) { create(:barcode_item, barcodeable: item) }

    it "updates a counter in Item whenever it tracks a new barcode" do
      expect { barcode_item }.to change { item.barcode_count }.to(1)
    end

    # These are scopes that are expressly to integrate with Filterable
    context "filters >" do
      it "->item_id shows only barcodes for a specific item_id" do
        barcode_item
        create(:barcode_item)
        results = BarcodeItem.barcodeable_id(item.id)
        expect(results).to eq([barcode_item])
      end
    end

    context "scopes >" do
      it "->for_csv_export will accept an organization and provide all barcodes for that org" do
        barcode_item
        create(:barcode_item, organization: create(:organization))
        results = BarcodeItem.for_csv_export(barcode_item.organization)
        expect(results).to eq([barcode_item])
      end

      it "#by_item_partner_key returns barcodes that match the partner key" do
        i1 = create(:item, base_item: BaseItem.first)
        i2 = create(:item, base_item: BaseItem.last)
        b1 = create(:barcode_item, barcodeable: i1)
        create(:barcode_item, barcodeable: i2)
        expect(BarcodeItem.by_item_partner_key(i1.partner_key).first).to eq(b1)
      end

      it "->by_value returns the barcode with that value" do
        b1 = create(:barcode_item, value: "DEADBEEF")
        create(:barcode_item, value: "IDDQD")
        expect(BarcodeItem.by_value("DEADBEEF").first).to eq(b1)
      end
    end

    context "validations >" do
      it "is valid only with an organization" do
        expect(build(:barcode_item, organization: nil)).not_to be_valid
        org = Organization.try(:first) || create(:organization)
        expect(build(:barcode_item, organization: org)).to be_valid
      end

      it "does not enforces value uniqueness across organizations" do
        barcode = create(:barcode_item, value: "DEADBEEF", organization: @organization)
        expect(build(:barcode_item, value: barcode.value, organization: create(:organization, skip_items: true))).to be_valid
      end

      it "enforces value uniqueness within the organization" do
        barcode = create(:barcode_item, value: "DEADBEEF", organization: @organization)
        expect(build(:barcode_item, value: barcode.value, organization: @organization)).not_to be_valid
      end

      it "allows multiple barcodes to point at the same item" do
        item = create(:item, organization: @organization)
        create(:barcode_item, organization: @organization, barcodeable: item)
        expect(build(:barcode_item, organization: @organization, barcodeable: item)).to be_valid
      end

      include_examples "common barcode tests", :barcode_item
    end

    describe "to_h >" do
      it "emits a hash for a line_item" do
        expect(barcode_item.to_h).to eq(barcodeable_id: barcode_item.barcodeable_id, barcodeable_type: barcode_item.barcodeable_type, quantity: barcode_item.quantity)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
