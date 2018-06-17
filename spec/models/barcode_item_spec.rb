# == Schema Information
#
# Table name: barcode_items
#
#  id               :bigint(8)        not null, primary key
#  value            :string
#  barcodeable_id   :integer
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organization_id  :integer
#  global           :boolean          default(FALSE)
#  barcodeable_type :string           default("Item")
#

RSpec.describe BarcodeItem, type: :model do
  # let!(:organization) { Organization.first || create(:organization) }

  context "global barcodes" do
    it "updates a counter in CanonicalItem whenever it tracks a new barcode" do
      item = create(:canonical_item)
      expect do
        create(:global_barcode_item, barcodeable: item)
      end.to change { item.barcode_count }.to(1)
    end

    context "Filters >" do
      it "->barcodeable_id shows only barcodes for a specific barcodeable_id" do
        item = create(:canonical_item)
        barcode_item = create(:global_barcode_item, barcodeable: item)
        create(:global_barcode_item)
        results = BarcodeItem.barcodeable_id(item.id)
        expect(results.length).to eq(1)
        expect(results.first).to eq(barcode_item)
      end
    end

    context "validations >" do
      it "is valid with or without an organization" do
        expect(build(:global_barcode_item, organization: nil)).to be_valid
        org = Organization.try(:first) || create(:organization)
        expect(build(:global_barcode_item, organization: org)).to be_valid
      end
      describe "value >" do
        it "requires a value" do
          expect(build(:global_barcode_item, value: nil)).not_to be_valid
        end
        it "enforces uniqueness in barcode value" do
          barcode_item = create(:global_barcode_item)
          expect(build(:global_barcode_item, value: barcode_item.value)).not_to be_valid
        end
      end

      describe "item >" do
        it "is invalid without an item associated with it" do
          expect(build(:global_barcode_item, barcodeable: nil)).not_to be_valid
        end
      end

      describe "quantity >" do
        it "is not nil" do
          expect(build(:global_barcode_item, quantity: nil)).not_to be_valid
        end
        it "is an integer" do
          expect(build(:global_barcode_item, quantity: "aaa")).not_to be_valid
        end
        it "is not a negative number" do
          expect(build(:global_barcode_item, quantity: -1)).not_to be_valid
        end
      end
    end
  end

  context "organization barcodes" do
    it "updates a counter in Item whenever it tracks a new barcode" do
      item = create(:item)
      expect do
        create(:barcode_item, barcodeable: item)
      end.to change { item.barcode_count }.to(1)
    end

    context "Filters >" do
      it "->item_id shows only barcodes for a specific item_id" do
        item = create(:item)
        barcode_item = create(:barcode_item, barcodeable: item)
        create(:barcode_item)
        results = BarcodeItem.barcodeable_id(item.id)
        expect(results.length).to eq(1)
        expect(results.first).to eq(barcode_item)
      end
    end

    context "validations >" do
      it "is valid only with an organization" do
        expect(build(:barcode_item, organization: nil)).not_to be_valid
        org = Organization.try(:first) || create(:organization)
        expect(build(:barcode_item, organization: org)).to be_valid
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
          barcode_item = create(:barcode_item)
          barcode_item.barcodeable = nil
          expect(barcode_item).not_to be_valid
        end
      end

      describe "quantity >" do
        it "is not nil" do
          expect(build(:barcode_item, quantity: nil)).not_to be_valid
        end
        it "is an integer" do
          expect(build(:barcode_item, quantity: "aaa")).not_to be_valid
        end
        it "is not a negative number" do
          expect(build(:barcode_item, quantity: -1)).not_to be_valid
        end
      end
    end

    # TODO: Determine how barcode items should act re: global barcodes / local barcodes and items vs. canonical items

    describe "to_h >" do
      it "emits a hash for a line_item" do
        barcode_item = create :barcode_item
        expect(barcode_item.to_h).to eq(barcodeable_id: barcode_item.barcodeable_id, barcodeable_type: barcode_item.barcodeable_type, quantity: barcode_item.quantity)
      end
    end
  end
end
