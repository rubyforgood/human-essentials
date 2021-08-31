describe Exports::ExportDistributionsCSVService do
  describe '#generate_csv_data' do
    subject { described_class.new(distribution_ids: distribution_ids).generate_csv_data }
    let(:distribution_ids) { distributions.map(&:id) }
    let(:distributions) do
      Array.new(3) do
        create(
          :distribution,
          :with_items,
          item:
          FactoryBot.create(:item, name: Faker::Appliance.equipment),
          issued_at: Time.current
        )
      end.reverse
    end
    let(:expected_headers) do
      [
        "Partner",
        "Date of Distribution",
        "Source Inventory",
        "Total Items",
        "Total Value",
        "Delivery Method",
        "State",
        "Agency Representative"
      ] + expected_item_headers
    end
    let(:expected_item_headers) do
      item_names = distributions.map do |distribution|
        distribution.line_items.map(&:item).map(&:name)
      end.flatten

      item_names.sort.uniq
    end

    it 'should match the expected content for the csv' do
      expect(subject[0]).to eq(expected_headers)

      distributions.each_with_index do |distribution, idx|
        row = [
          distribution.partner.name,
          distribution.issued_at.strftime("%m/%d/%Y"),
          distribution.storage_location.name,
          distribution.line_items.total,
          distribution.cents_to_dollar(distribution.line_items.total_value),
          distribution.delivery_method,
          distribution.state,
          distribution.agency_rep
        ]

        row += Array.new(expected_item_headers.size, 0)

        distribution.line_items.includes(:item).each do |line_item|
          item_name = line_item.item.name
          item_column_idx = expected_headers.index(item_name)
          row[item_column_idx] = line_item.quantity
        end

        expect(subject[idx + 1]).to eq(row)
      end
    end
  end
end
