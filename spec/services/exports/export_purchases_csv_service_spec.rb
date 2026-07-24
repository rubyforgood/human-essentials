RSpec.describe Exports::ExportPurchasesCSVService do
  describe "#generate_csv" do
    let(:organization) { create(:organization) }
    let(:storage_location) { create(:storage_location, organization: organization, name: "Test Storage Location") }

    subject { described_class.new(purchase_ids: purchase_ids, organization: organization).generate_csv }
    let(:purchase_ids) { purchases.map(&:id) }
    let(:duplicate_item) { create(:item, name: "Dupe Item", organization: organization) }

    let(:purchase_items_and_quantities) {
      [
        [
          [duplicate_item, 5],
          [create(:item, name: "A Item", organization: organization), 7],
          [duplicate_item, 3]
        ],
        [[create(:item, name: "B Item", organization: organization), 1]],
        [[create(:item, name: "C Item", organization: organization), 2]],
        [[create(:item, name: "E Item", organization: organization), 3]]
      ]
    }

    let(:purchases) do
      purchase_items_and_quantities.each_with_index.map do |items, i|
        purchase = create(
          :purchase,
          organization: organization,
          storage_location: storage_location,
          vendor: create(:vendor, business_name: "Test Vendor #{i}", organization: organization),
          issued_at: "2025-01-0#{i + 1}",
          comment: "This is the #{i}-th purchase in the test.",
          amount_spent_in_cents: i * 4 + 555,
          amount_spent_on_diapers_cents: i + 100,
          amount_spent_on_adult_incontinence_cents: i + 125,
          amount_spent_on_period_supplies_cents: i + 130,
          amount_spent_on_other_cents: i + 200
        )

        items.each do |(item, quantity)|
          purchase.line_items << create(:line_item, item: item, quantity: quantity)
        end

        purchase
      end
    end

    def expected_csv(fixture_name)
      Rails.root.join("spec/fixtures/files", fixture_name).read
    end

    it "should match the expected content for the csv" do
      expect(subject).to eq(expected_csv("purchases_export.csv"))
    end

    it "should include inactive items in the export with zero quantities" do
      create(:item, :inactive, name: "Inactive Item", organization: organization)

      expect(subject).to eq(expected_csv("purchases_export_with_inactive_item.csv"))
    end

    it "should include items that are not in any purchase with zero quantities" do
      create(:item, name: "Unused Item", organization: organization)

      expect(subject).to eq(expected_csv("purchases_export_with_unused_item.csv"))
    end

    context "when item names differ only by case" do
      let(:purchase_items_and_quantities) {
        [
          [[create(:item, name: "Banana", organization: organization), 2]]
        ]
      }

      it "should sort item columns case-insensitively, ASC" do
        # Create the other items in reverse-ASCII order to prove the sort is
        # case-insensitive rather than relying on creation order or ASCII order
        # (which would put "Zebra" before "apple").
        create(:item, name: "apple", organization: organization)
        create(:item, name: "Zebra", organization: organization)

        expect(subject).to eq(expected_csv("purchases_export_case_insensitive_sort.csv"))
      end
    end
  end
end
