RSpec.describe Exports::ExportDistributionsCSVService do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:partner) { create(:partner, name: "first partner", email: "firstpartner@gmail.com", notes: "just a note.", organization_id: organization.id) }

  describe '#generate_csv_data' do
    subject { described_class.new(distributions: distributions, organization: organization, filters: filters).generate_csv_data }

    let(:duplicate_item) { create(:item, name: "Dupe Item", value_in_cents: 300, organization: organization) }

    let(:expected_distributions) {
      [
        {
          issued_at: "01/01/2025",
          created_at: "01/01/2025",
          delivery_method: "shipped",
          shipping_cost: "12.09",
          state: "scheduled",
          agency_rep: "",
          comment: "comment 1",
          line_items: [
            {
              item: duplicate_item,
              quantity: 5
            },
            {
              item: create(:item, name: "A Item", value_in_cents: 1000, organization: organization),
              quantity: 7
            },
            {
              item: duplicate_item,
              quantity: 3
            }
          ],
          filtered_quantity: 8,
          filtered_total_value: Money.new(2400).to_f
        },
        {
          issued_at: "02/02/2025",
          created_at: "02/02/2025",
          delivery_method: "shipped",
          shipping_cost: "13.09",
          state: "scheduled",
          agency_rep: "",
          comment: "comment 2",
          line_items: [
            {
              item: create(:item, name: "B Item", value_in_cents: 2000, organization: organization),
              quantity: 1
            }
          ],
          filtered_quantity: 0,
          filtered_total_value: Money.new(0).to_f
        },
        {
          issued_at: "03/03/2025",
          created_at: "03/03/2025",
          delivery_method: "shipped",
          shipping_cost: "14.09",
          state: "scheduled",
          agency_rep: "",
          comment: "comment 3",
          line_items: [
            {
              item: create(:item, name: "C Item", value_in_cents: 3000, organization: organization),
              quantity: 2
            }
          ],
          filtered_quantity: 0,
          filtered_total_value: Money.new(0).to_f
        },
        {
          issued_at: "04/04/2025",
          created_at: "04/04/2025",
          delivery_method: "shipped",
          shipping_cost: "15.09",
          state: "scheduled",
          agency_rep: "",
          comment: "comment 4",
          line_items: [
            {
              item: create(:item, name: "E Item", value_in_cents: 4000, organization: organization),
              quantity: 3
            }
          ],
          filtered_quantity: 0,
          filtered_total_value: Money.new(0).to_f
        }
      ]
    }

    let(:distributions) do
      expected_distributions.each_with_index.map do |dist, i|
        distribution = create(
          :distribution,
          partner: partner,
          organization: organization,
          storage_location: storage_location,
          created_at: dist[:created_at],
          issued_at: dist[:issued_at],
          delivery_method: dist[:delivery_method],
          shipping_cost: dist[:shipping_cost],
          state: dist[:state],
          agency_rep: dist[:agency_rep],
          comment: dist[:comment]
        )

        dist[:line_items].each do |line_item|
          distribution.line_items << create(:line_item, quantity: line_item[:quantity], item: line_item[:item])
        end

        distribution
      end
    end

    let(:expected_items) do
      # A Item|A Item In-Kind Value|B Item|...In-Kind Value|C Item 2|... In-Kind Value|Dupe Item|... In-Kind Value|E Item|...In-Kind Value
      [
        [
          {quantity: 7, value: Money.new(7000), item_id: 2},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 8, value: Money.new(2400), item_id: 1},
          {quantity: 0, value: Money.new(0), item_id: nil}
        ],
        [
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 1, value: Money.new(2000), item_id: 3},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil}
        ],
        [
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 2, value: Money.new(6000), item_id: 4},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil}
        ],
        [
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 0, value: Money.new(0), item_id: nil},
          {quantity: 3, value: Money.new(12000), item_id: 5}
        ]
      ]
    end

    let(:item_id) { duplicate_item.id }
    let(:item_name) { duplicate_item.name }
    let(:filters) { {by_item_id: item_id} }

    let(:non_item_headers) do
      [
        "Partner",
        "Initial Allocation",
        "Scheduled for",
        "Source Inventory",
        "Total Number of #{item_name}",
        "Total Value of #{item_name}",
        "Delivery Method",
        "Shipping Cost",
        "Status",
        "Agency Representative",
        "Comments"
      ]
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      let(:item_headers) { ["A Item", "B Item", "C Item", "Dupe Item", "E Item"] }
      let(:expected_headers) { non_item_headers + item_headers }

      it 'should match the expected content without in-kind value of each item for the csv' do
        csv = [expected_headers]
        expected_distributions.zip(expected_items).each_with_index do |(expected_dist, expected_item), idx|
          csv.append([
            partner.name,
            expected_dist[:created_at],
            expected_dist[:issued_at],
            storage_location.name,
            expected_dist[:filtered_quantity],
            expected_dist[:filtered_total_value],
            expected_dist[:delivery_method],
            "$#{expected_dist[:shipping_cost].to_f}",
            expected_dist[:state],
            expected_dist[:agency_rep],
            expected_dist[:comment],
            *expected_item.map { |item| item[:quantity] }
          ])
        end

        expect(subject).to eq(csv)
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      let(:item_headers) {
        [
          "A Item", "A Item In-Kind Value",
          "B Item", "B Item In-Kind Value",
          "C Item", "C Item In-Kind Value",
          "Dupe Item", "Dupe Item In-Kind Value",
          "E Item", "E Item In-Kind Value"
        ]
      }
      let(:expected_headers) { non_item_headers + item_headers }

      it 'should match the expected content with in-kind value of each item for the csv' do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)
        csv = [expected_headers]
        expected_distributions.zip(expected_items).each_with_index do |(expected_dist, expected_item), idx|
          csv.append([
            partner.name,
            expected_dist[:created_at],
            expected_dist[:issued_at],
            storage_location.name,
            expected_dist[:filtered_quantity],
            expected_dist[:filtered_total_value],
            expected_dist[:delivery_method],
            "$#{expected_dist[:shipping_cost].to_f}",
            expected_dist[:state],
            expected_dist[:agency_rep],
            expected_dist[:comment],
            *expected_item.flat_map { |item| [item[:quantity], item[:value]] }
          ])
        end

        expect(subject).to eq(csv)
      end
    end

    context 'when a new item is added' do
      let(:item_headers) { ["A Item", "B Item", "C Item", "Dupe Item", "E Item", "New Item"] }
      let(:expected_headers) { non_item_headers + item_headers }
      let(:new_item_name) { "New Item" }
      let(:original_columns_count) { 15 }
      before do
        # if distributions are not created before new item
        # then additional records will be created
        distributions
        create(:item, name: new_item_name, organization: organization)
      end

      it 'should add it to the end of the row' do
        expect(subject[0]).to eq(expected_headers)
          .and end_with(new_item_name)
          .and have_attributes(size: 17)
      end

      it 'should show up with a 0 quantity if there are none of this item in any distribution' do
        csv = [expected_headers]
        expected_distributions.zip(expected_items).each_with_index do |(expected_dist, expected_item), idx|
          csv.append([
            partner.name,
            expected_dist[:created_at],
            expected_dist[:issued_at],
            storage_location.name,
            expected_dist[:filtered_quantity],
            expected_dist[:filtered_total_value],
            expected_dist[:delivery_method],
            "$#{expected_dist[:shipping_cost].to_f}",
            expected_dist[:state],
            expected_dist[:agency_rep],
            expected_dist[:comment],
            *expected_item.map { |item| item[:quantity] },
            0
          ])
        end

        expect(subject).to eq(csv)
      end
    end

    context 'when there are no distributions but the report is requested' do
      let(:item_headers) { ["Dupe Item"] }
      let(:expected_headers) { non_item_headers + item_headers }
      subject { described_class.new(distributions: [], organization: organization, filters: filters).generate_csv_data }
      it 'returns a csv with only headers and no rows' do
        header_row = subject[0]
        expect(header_row).to eq(expected_headers)
        expect(header_row.last).to eq(item_headers[0])
        expect(subject.size).to eq(1)
      end
    end
  end
end
