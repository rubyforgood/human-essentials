RSpec.describe Exports::ExportDonationsCSVService do
  describe '#generate_csv_data' do
    let(:organization) { create(:organization) }
    subject { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv_data }
    let(:donation_ids) { donations.map(&:id) }
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

    let(:donations) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        donation = create(
          :donation,
          donation_site: create(
            :donation_site, name: "Space Needle #{i}",
          ),
          issued_at: start_time + i.days,
          comment: "This is the #{i}-th donation in the test."
        )

        items.each do |(item, quantity)|
          donation.line_items << create(
            :line_item, quantity: quantity, item: item
          )
        end

        donation
      end
    end

    let(:expected_headers) do
      [
        "Source",
        "Date",
        "Details",
        "Storage Location",
        "Quantity of Items",
        "Variety of Items",
        "In-Kind Total",
        "Comments"
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

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      it 'should match the expected content without in-kind value of each item for the csv' do
        expect(subject[0]).to eq(expected_headers)

        donations.zip(total_item_quantities).each_with_index do |(donation, total_item_quantity), idx|
          row = [
            donation.source,
            donation.issued_at.strftime("%F"),
            donation.details,
            donation.storage_view,
            donation.line_items.total,
            total_item_quantity.count(&:positive?),
            donation.in_kind_value_money,
            donation.comment
          ]

          row += total_item_quantity

          expect(subject[idx + 1]).to eq(row)
        end
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      let(:expected_item_headers) do
        expect(item_names).not_to be_empty

        item_names.flat_map { |name| [name, "#{name} In-Kind Value"] }
      end
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

        donations.zip(expected_items).each_with_index do |(donation, expected_item), idx|
          row = [
            donation.source,
            donation.issued_at.strftime("%F"),
            donation.details,
            donation.storage_view,
            donation.line_items.total,
            expected_item.map { |item| item[:quantity] }.count(&:positive?),
            donation.in_kind_value_money,
            donation.comment,
            *expected_item.flat_map { |item| [item[:quantity], item[:value]] }
          ]

          expect(subject[idx + 1]).to eq(row)
        end
      end
    end
  end
end
