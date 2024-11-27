RSpec.describe Exports::ExportDonationsCSVService do
  describe '#generate_csv_data' do
    subject { described_class.new(donation_ids: donation_ids).generate_csv_data }
    let(:donation_ids) { donations.map(&:id) }
    let(:duplicate_item) { FactoryBot.create(:item) }
    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [FactoryBot.create(:item), 7],
          [duplicate_item, 3]
        ],
        *(Array.new(3) do |i|
          [[FactoryBot.create(
            :item, name: "item_#{i}"
          ), i + 1]]
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

    it 'should match the expected content for the csv' do
      expect(subject[0]).to eq(expected_headers)

      donations.zip(total_item_quantities).each_with_index do |(donation, total_item_quantity), idx|
        row = [
          donation.source,
          donation.issued_at.strftime("%F"),
          donation.details,
          donation.storage_view,
          donation.line_items.total,
          total_item_quantity.count(&:positive?),
          donation.comment
        ]

        row += total_item_quantity

        expect(subject[idx + 1]).to eq(row)
      end
    end
  end
end
