describe Exports::ExportDistributionsCSVService, skip_seed: true do
  describe '#generate_csv_data' do
    subject { described_class.new(distribution_ids: distribution_ids).generate_csv_data }
    let(:distribution_ids) { distributions.map(&:id) }

    let(:duplicate_item) do
      FactoryBot.create(
        :item, name: Faker::Appliance.equipment
      )
    end

    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [
            FactoryBot.create(:item, name: Faker::Appliance.equipment),
            7
          ],
          [duplicate_item, 3]
        ],
        *(Array.new(3) do |i|
          [[FactoryBot.create(
            :item, name: Faker::Appliance.equipment
          ), i + 1]]
        end)
      ]
    end

    let(:item_names) { items_lists.flatten(1).map(&:first).map(&:name).sort.uniq }

    let(:distributions) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        distribution = create(
          :distribution,
          issued_at: start_time - i.days
        )

        items.each do |(item, quantity)|
          distribution.line_items << create(
            :line_item, quantity: quantity, item: item
          )
        end

        distribution
      end
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
      expect(item_names).not_to be_empty

      item_names
    end

    it 'should match the expected content for the csv' do
      expect(subject[0]).to eq(expected_headers)

      distributions.zip(total_item_quantities).each_with_index do |(distribution, total_item_quantity), idx|
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

        row += total_item_quantity

        expect(subject[idx + 1]).to eq(row)
      end
    end
  end
end
