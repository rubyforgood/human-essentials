RSpec.describe Exports::ExportTransfersCSVService do
  let!(:organization) { create(:organization) }

  describe "#generate_csv_data" do
    subject { described_class.new(transfers:, organization:).generate_csv_data }

    let(:from_location) { create(:storage_location, name: "From Location") }
    let(:to_location) { create(:storage_location, name: "To Location") }
    let(:duplicate_item) { create(:item, name: "Dupe Item") }

    let(:items_lists) do # Used to created four transfers
      [
        [
          [duplicate_item, 5],
          [create(:item), 7],
          [duplicate_item, 3]
        ],

        *(Array.new(3) do |i|
          [[create(:item), i + 1]]
        end)
      ]
    end

    let(:transfers) do
      items_lists.map do |items|
        transfer = create(:transfer, from: from_location, to: to_location)

        items.each do |(item, quantity)|
          transfer.line_items << create(:line_item, quantity:, item:)
        end

        transfer
      end
    end

    let(:all_org_items) { organization.items.sort_by { |item| item.name.downcase } }

    let(:total_item_quantities) do
      template = all_org_items.pluck(:name).index_with(0)

      items_lists.map do |items_list|
        row = template.dup
        items_list.each do |(item, quantity)|
          row[item.name] += quantity
        end
        row.values
      end
    end

    let(:non_item_headers) { ["From", "To", "Date", "Comment", "Total Moved"] }
    let(:expected_headers) { non_item_headers + all_org_items.pluck(:name) }

    it "should match the expected content for the csv" do
      expect(subject[0]).to eq(expected_headers)

      transfers.zip(total_item_quantities).each_with_index do |(transfer, total_item_quantity), idx|
        row = [
          transfer.from.name,
          transfer.to.name,
          transfer.created_at.strftime("%F"),
          transfer.comment,
          transfer.line_items.total
        ]
        row += total_item_quantity

        expect(subject[idx + 1]).to eq(row)
      end
    end

    context "when a new item is added to the organization" do
      let!(:new_item) { create(:item, name: "New Item") }

      it "should be included as the last column of the csv" do
        expect(subject[0]).to eq(expected_headers).and end_with(new_item.name)
      end

      it "should have a quantity of 0 if this item isn't part of any transfer" do
        transfers.zip(total_item_quantities).each_with_index do |(transfer, total_item_quantity), idx|
          row = [
            transfer.from.name,
            transfer.to.name,
            transfer.created_at.strftime("%F"),
            transfer.comment,
            transfer.line_items.total
          ]
          row += total_item_quantity

          expect(subject[idx + 1]).to eq(row).and end_with(0)
        end
      end
    end

    context "when there are no transfers but the report is requested" do
      let(:transfers) { Transfer.none }

      it "returns a csv with only headers and no rows" do
        expect(subject.size).to eq(1)
        header_row = subject[0]
        expect(header_row).to eq(expected_headers)
      end
    end

    context "when an organization's item exists but isn't in any transfer" do
      let(:unused_item) { create(:item, name: "Unused Item", organization: organization) }
      let(:generated_csv_data) do
        # Force unused_item to be created first
        unused_item
        described_class.new(transfers: transfers, organization: organization).generate_csv_data
      end

      it "should include the unused item as a column with 0 quantities" do
        expect(generated_csv_data[0]).to include(unused_item.name)

        transfers.each_with_index do |_, idx|
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
        described_class.new(transfers: transfers, organization: organization).generate_csv_data
      end

      it "should include the inactive item as a column with 0 quantities" do
        expect(generated_csv_data[0]).to include(inactive_item.name)

        transfers.each_with_index do |_, idx|
          row = generated_csv_data[idx + 1]
          item_column_index = generated_csv_data[0].index(inactive_item.name)
          expect(row[item_column_index]).to eq(0)
        end
      end
    end

    context "when generating CSV output" do
      let(:generated_csv) { described_class.new(transfers: transfers, organization: organization).generate_csv }

      it "returns a valid CSV string" do
        expect(generated_csv).to be_a(String)
        expect { CSV.parse(generated_csv) }.not_to raise_error
      end

      it "includes headers as first row" do
        csv_rows = CSV.parse(generated_csv)
        expect(csv_rows.first).to eq(expected_headers)
      end

      it "includes data for all transfers" do
        csv_rows = CSV.parse(generated_csv)
        expect(csv_rows.count).to eq(transfers.count + 1) # +1 for headers
      end
    end

    context "when items have different cases" do
      let(:item_names) { ["Zebra", "apple", "Banana"] }
      let(:expected_order) { ["apple", "Banana", "Zebra"] }
      let(:transfer) { create(:transfer, from: from_location, to: to_location) }
      let(:case_sensitive_csv_data) do
        # Create items in random order to ensure sort is working
        item_names.shuffle.each do |name|
          create(:item, name: name, organization: organization)
        end

        described_class.new(transfers: [transfer], organization: organization).generate_csv_data
      end

      it "should sort item columns case-insensitively, ASC" do
        # Get just the item columns by removing the known base headers
        item_columns = case_sensitive_csv_data[0] - non_item_headers

        # Check that the remaining columns match our expected case-insensitive sort
        expect(item_columns).to eq(expected_order)
      end
    end
  end
end
