describe Exports::ExportDistributionsCSVService do

  describe '#generate_csv' do
    subject { described_class.new(distributions).generate_csv }
    let(:distributions) do
      Array.new(3) do
        create(
          :distribution,
          :with_items,
          item:
          FactoryBot.create(:item, name: Faker::Appliance.equipment),
          issued_at: 3.days.ago
        )
      end
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
      item_names = distributions.map(&:line_items).flatten.map(&:item).map do |item|
        item.name
      end

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

        row = row + Array.new(expected_item_headers.size, 0)

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

