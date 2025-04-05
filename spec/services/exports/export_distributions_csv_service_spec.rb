RSpec.describe Exports::ExportDistributionsCSVService do
  let(:organization) { create(:organization) }

  describe '#generate_csv_data' do
    subject { described_class.new(distributions: distributions, organization: organization, filters: filters).generate_csv_data }

    let(:duplicate_item) { create(:item, name: "Dupe Item", value_in_cents: 300, organization: organization) }

    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [create(:item, name: "A item", value_in_cents: 100, organization: organization), 7],
          [duplicate_item, 3]
        ],

        *(Array.new(3) do |i|
          [[create(:item, name: "B item #{i}", value_in_cents: (i + 1) * 1000, organization: organization), i + 1]]
        end)
      ]
    end

    let(:item_names) { items_lists.flatten(1).map(&:first).map(&:name).sort.uniq }

    let(:distributions) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        distribution = create(
          :distribution,
          issued_at: start_time - i.days, delivery_method: "shipped", shipping_cost: "12.09",
          organization: organization
        )

        items.each do |(item, quantity)|
          distribution.line_items << create(
            :line_item, quantity: quantity, item: item
          )
        end

        distribution
      end
    end

    let(:item_id) { duplicate_item.id }
    let(:item_name) { duplicate_item.name }
    let(:filters) { {by_item_id: item_id} }
    let(:all_org_items) { Item.where(organization:).uniq.sort_by { |item| item.name.downcase } }

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

    let(:expected_headers) { non_item_headers + all_org_items.pluck(:name) }

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      it 'should match the expected content without in-kind value of each item for the csv' do
        expect(subject[0]).to eq(expected_headers)

        distributions.zip(total_item_quantities).each_with_index do |(distribution, total_item_quantity), idx|
          row = [
            distribution.partner.name,
            distribution.created_at.strftime("%m/%d/%Y"),
            distribution.issued_at.strftime("%m/%d/%Y"),
            distribution.storage_location.name,
            distribution.line_items.where(item_id: item_id).total,
            distribution.cents_to_dollar(distribution.line_items.where(item_id: item_id).total_value),
            distribution.delivery_method,
            "$#{distribution.shipping_cost.to_f}",
            distribution.state,
            distribution.agency_rep,
            distribution.comment
          ]

          row += total_item_quantity

          expect(subject[idx + 1]).to eq(row)
        end
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      let(:expected_headers) { non_item_headers + all_org_items.pluck(:name).flat_map { |h| [h, "#{h} In-Kind Value"] } }

      let(:expected_items) do
        # A item|A item In-Kind Value|B item 1|...In-Kind Value|B item 2|... In-Kind Value|B item 3|... In-Kind Value|Dupe Item|...In-Kind Value
        [
          [
            {quantity: 7, value: Money.new(700), item_id: 2},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 8, value: Money.new(2400), item_id: 1}
          ],
          [
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 1, value: Money.new(1000), item_id: 3},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil}
          ],
          [
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 2, value: Money.new(4000), item_id: 4},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil}
          ],
          [
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 0, value: Money.new(0), item_id: nil},
            {quantity: 3, value: Money.new(9000), item_id: 5},
            {quantity: 0, value: Money.new(0), item_id: nil}
          ]
        ]
      end

      it 'should match the expected content with in-kind value of each item for the csv' do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)
        expect(subject[0]).to eq(expected_headers)

        distributions.zip(expected_items).each_with_index do |(distribution, expected_item), idx|
          row = [
            distribution.partner.name,
            distribution.created_at.strftime("%m/%d/%Y"),
            distribution.issued_at.strftime("%m/%d/%Y"),
            distribution.storage_location.name,
            distribution.line_items.where(item_id: item_id).total,
            Money.new(distribution.line_items.where(item_id: item_id).total_value).to_f,
            distribution.delivery_method,
            "$#{distribution.shipping_cost.to_f}",
            distribution.state,
            distribution.agency_rep,
            distribution.comment,
            *expected_item.flat_map { |item| [item[:quantity], item[:value]] }
          ]

          expect(subject[idx + 1]).to eq(row)
        end
      end
    end

    context 'when a new item is added' do
      let(:new_item_name) { "new item" }
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
        distributions.zip(total_item_quantities).each_with_index do |(distribution, total_item_quantity), idx|
          row = [
            distribution.partner.name,
            distribution.created_at.strftime("%m/%d/%Y"),
            distribution.issued_at.strftime("%m/%d/%Y"),
            distribution.storage_location.name,
            distribution.line_items.where(item_id: item_id).total,
            distribution.cents_to_dollar(distribution.line_items.where(item_id: item_id).total_value),
            distribution.delivery_method,
            "$#{distribution.shipping_cost.to_f}",
            distribution.state,
            distribution.agency_rep,
            distribution.comment
          ]

          row += total_item_quantity

          expect(subject[idx + 1]).to eq(row)
            .and end_with(0)
            .and have_attributes(size: 17)
        end
      end
    end

    context 'when there are no distributions but the report is requested' do
      subject { described_class.new(distributions: [], organization: organization, filters: filters).generate_csv_data }
      it 'returns a csv with only headers and no rows' do
        header_row = subject[0]
        expect(header_row).to eq(expected_headers)
        expect(header_row.last).to eq(all_org_items.last.name)
        expect(subject.size).to eq(1)
      end
    end
  end
end
