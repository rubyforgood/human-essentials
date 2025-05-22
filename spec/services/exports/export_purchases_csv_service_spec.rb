RSpec.describe Exports::ExportPurchasesCSVService do
  describe "#generate_csv_data" do
    let(:organization) { create(:organization) }
    subject { described_class.new(purchase_ids: purchase_ids, organization: organization).generate_csv_data }
    let(:purchase_ids) { purchases.map(&:id) }
    let(:duplicate_item) do
      FactoryBot.create(
        :item, name: Faker::Appliance.unique.equipment, organization: organization
      )
    end
    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [
            FactoryBot.create(
              :item, name: Faker::Appliance.unique.equipment, organization: organization
            ),
            7
          ],
          [duplicate_item, 3]
        ],
        *(Array.new(3) do |i|
          [[FactoryBot.create(
            :item, name: Faker::Appliance.unique.equipment, organization: organization
          ), i + 1]]
        end)
      ]
    end

    let(:item_names) { items_lists.flatten(1).map(&:first).map(&:name).sort.uniq }

    let(:purchases) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        purchase = create(
          :purchase,
          organization: organization,
          vendor: create(
            :vendor, business_name: "Vendor Name #{i}", organization: organization
          ),
          issued_at: start_time + i.days,
          comment: "This is the #{i}-th purchase in the test.",
          amount_spent_in_cents: i * 4 + 555,
          amount_spent_on_diapers_cents: i + 100,
          amount_spent_on_adult_incontinence_cents: i + 125,
          amount_spent_on_period_supplies_cents: i + 130,
          amount_spent_on_other_cents: i + 200
        )

        items.each do |(item, quantity)|
          purchase.line_items << create(
            :line_item, quantity: quantity, item: item
          )
        end

        purchase
      end
    end

    let(:expected_headers) do
      [
        "Purchases from",
        "Storage Location",
        "Purchased Date",
        "Quantity of Items",
        "Variety of Items",
        "Amount Spent",
        "Spent on Diapers",
        "Spent on Adult Incontinence",
        "Spent on Period Supplies",
        "Spent on Other",
        "Comment"
      ] + expected_item_headers
    end

    let(:total_item_quantities) do
      template = item_names.index_with(0)

      items_lists.map do |items_list|
        row = template.dup
        items_list.each do |(item, quantity)|
          row[item.name] += quantity
        end
        row.values
      end
    end

    let(:expected_item_headers) do
      expect(item_names).not_to be_empty

      item_names
    end

    it "should match the expected content for the csv" do
      expect(subject[0]).to eq(expected_headers)

      purchases.zip(total_item_quantities).each_with_index do |(purchase, total_item_quantity), idx|
        row = [
          purchase.vendor.try(:business_name),
          purchase.storage_view,
          purchase.issued_at.strftime("%F"),
          purchase.line_items.total,
          total_item_quantity.count(&:positive?),
          purchase.amount_spent,
          purchase.amount_spent_on_diapers,
          purchase.amount_spent_on_adult_incontinence,
          purchase.amount_spent_on_period_supplies,
          purchase.amount_spent_on_other,
          purchase.comment
        ]

        row += total_item_quantity

        expect(subject[idx + 1]).to eq(row)
      end
    end

    context "when an organization's item exists but isn't in any purchase" do
      let(:unused_item) { create(:item, name: "Unused Item", organization: organization) }
      let(:generated_csv_data) do
        # Force unused_item to be created first
        unused_item
        described_class.new(purchase_ids: purchases.map(&:id), organization: organization).generate_csv_data
      end

      it "should include the unused item as a column with 0 quantities" do
        expect(generated_csv_data[0]).to include(unused_item.name)

        purchases.each_with_index do |_, idx|
          row = generated_csv_data[idx + 1]
          item_column_index = generated_csv_data[0].index(unused_item.name)
          expect(row[item_column_index]).to eq(0)
        end
      end
    end

    context "when an organization's item is inactive" do
      let(:inactive_item) { create(:item, name: "Inactive Item", active: false, organization: organization) }
      let(:generated_csv_data) do
        # Force inactive_item to be created first
        inactive_item
        described_class.new(purchase_ids: purchases.map(&:id), organization: organization).generate_csv_data
      end

      it "should include the inactive item as a column with 0 quantities" do
        expect(generated_csv_data[0]).to include(inactive_item.name)

        purchases.each_with_index do |_, idx|
          row = generated_csv_data[idx + 1]
          item_column_index = generated_csv_data[0].index(inactive_item.name)
          expect(row[item_column_index]).to eq(0)
        end
      end
    end

    context "when generating CSV output" do
      let(:generated_csv) { described_class.new(purchase_ids: purchase_ids, organization: organization).generate_csv }

      it "returns a valid CSV string" do
        expect(generated_csv).to be_a(String)
        expect { CSV.parse(generated_csv) }.not_to raise_error
      end

      it "includes headers as first row" do
        csv_rows = CSV.parse(generated_csv)
        expect(csv_rows.first).to eq(expected_headers)
      end

      it "includes data for all purchases" do
        csv_rows = CSV.parse(generated_csv)
        expect(csv_rows.count).to eq(purchases.count + 1) # +1 for headers
      end
    end

    context "when items have different cases" do
      let(:item_names) { ["Zebra", "apple", "Banana"] }
      let(:expected_order) { ["apple", "Banana", "Zebra"] }
      let(:purchase) { create(:purchase, organization: organization) }
      let(:case_sensitive_csv_data) do
        # Create items in random order to ensure sort is working
        item_names.shuffle.each do |name|
          create(:item, name: name, organization: organization)
        end

        described_class.new(purchase_ids: [purchase.id], organization: organization).generate_csv_data
      end

      it "should sort item columns case-insensitively, ASC" do
        # Get just the item columns by removing the known base headers
        item_columns = case_sensitive_csv_data[0] - expected_headers[0..-4] # plucks out the 3 items at the end

        # Check that the remaining columns match our expected case-insensitive sort
        expect(item_columns).to eq(expected_order)
      end
    end
  end
end
