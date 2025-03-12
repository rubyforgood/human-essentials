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
  end
end
