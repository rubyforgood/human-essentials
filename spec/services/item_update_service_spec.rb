# frozen_string_literal: true

require "rspec"

RSpec.describe ItemUpdateService, type: :service do
  describe ".call" do
    subject { described_class.new(item: item, params: params, request_unit_ids: request_unit_ids).call }

    let(:kit) { create(:kit) }
    let(:item) { create(:item, kit: kit) }
    let(:item2) { create(:item, kit: kit) }
    let(:params) do
      {
        name: "Updated Item Name",
        reporting_category: "pads",
        value_in_cents: 2000
      }
    end
    let(:request_unit_ids) { [] }
    let(:kit_value_in_cents) do
      kit.line_items.reduce(0) do |sum, li|
        item = Item.find(li.item_id)
        sum + item.value_in_cents.to_i * li.quantity.to_i
      end
    end

    context "params are ok" do
      it "returns a Result with success? true and the item" do
        result = subject
        expect(result).to be_a_kind_of(Result)
        expect(result.success?).to eq(true)
        expect(result.value).to eq(item)
      end

      it "updates the item attributes" do
        subject
        item.reload
        expect(item.name).to eq("Updated Item Name")
        expect(item.value_in_cents).to eq(2000)
      end

      it "updates the kit value_in_cents" do
        subject
        kit.reload
        expect(kit.value_in_cents).to eq(kit_value_in_cents)
      end
    end

    context "params are invalid" do
      let(:params) do
        {
          name: "" # Invalid as name can't be blank
        }
      end

      it "returns a Result with success? false and an error" do
        result = subject
        expect(result).to be_a_kind_of(Result)
        expect(result.success?).to eq(false)
        expect(result.error).to be_a(ActiveRecord::RecordInvalid)
        expect(result.error.message).to include("Validation failed: Name can't be blank")
      end

      it "does not update the item attributes" do
        original_name = item.name
        subject
        item.reload
        expect(item.name).to eq(original_name)
      end

      it "does not update the kit value_in_cents" do
        original_kit_value = kit.value_in_cents
        subject
        kit.reload
        expect(kit.value_in_cents).to eq(original_kit_value)
      end
    end
  end
end
