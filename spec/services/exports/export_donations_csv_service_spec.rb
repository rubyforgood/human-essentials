describe Exports::ExportDonationsCSVService do
  describe '#generate_csv_data' do
    subject { described_class.new(donation_ids: donation_ids).generate_csv_data }
    let(:donation_ids) { donations.map(&:id) }
    let(:donations) do
      start_time = Time.current
      Array.new(3) do |i|
        create(
          :donation,
          :with_items,
          donation_site: create(
            :donation_site, name: "Space Needle #{i}",
          ),
          item: FactoryBot.create(
            :item, name: Faker::Appliance.equipment
          ),
          issued_at: start_time + i.days,
          comment: "This is the #{i}-th donation in the test."
        )
      end
    end
    let(:expected_headers) do
      [
        "Source",
        "Date",
        "Donation Site",
        "Storage Location",
        "Quantity of Items",
        "Variety of Items",
        "Comments"
      ] + expected_item_headers
    end
    let(:expected_item_headers) do
      item_names = donations.map do |donation|
        donation.line_items.map(&:item).map(&:name)
      end.flatten

      expect(item_names).not_to be_empty

      item_names.sort.uniq
    end

    it 'should match the expected content for the csv' do
      expect(subject[0]).to eq(expected_headers)

      donations.each_with_index do |donation, idx|
        row = [
          donation.source_view,
          donation.issued_at.strftime("%F"),
          donation.donation_site.try(:name),
          donation.storage_view,
          donation.line_items.total,
          donation.line_items.size,
          donation.comment
        ]

        row += Array.new(expected_item_headers.size, 0)

        donation.line_items.includes(:item).each do |line_item|
          item_name = line_item.item.name
          item_column_idx = expected_headers.index(item_name)
          row[item_column_idx] = line_item.quantity
        end

        expect(subject[idx + 1]).to eq(row)
      end
    end
  end
end
