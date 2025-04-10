RSpec.describe Exports::ExportDonationsCSVService do
  describe '#generate_csv_data' do
    let(:organization) { create(:organization) }
    let(:storage_location) { create(:storage_location, organization: organization) }

    subject { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv_data }
    let(:donation_ids) { donations.map(&:id) }
    let(:duplicate_item) { create(:item, name: "Dupe Item", value_in_cents: 300, organization: organization) }

    let(:product_drive) { create(:product_drive, name: "product drive 1", organization: organization) }
    let(:manufacturer) { create(:manufacturer, name: "manufacturer 2", organization: organization) }
    let(:donation_site) { create(:donation_site, name: "site 3") }

    let(:expected_donations) {
      [
        {
          parameters: {
            issued_at: "2025-01-01",
            source: Donation::SOURCES[:product_drive],
            product_drive: product_drive,
            comment: "comment 1"
          },
          details: product_drive.name,
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
          variety: 2,
          quantity: 15,
          total_value: Money.new(9400).to_f
        },
        {
          parameters: {
            issued_at: "2025-02-02",
            source: Donation::SOURCES[:manufacturer],
            manufacturer: manufacturer,
            comment: "comment 2"
          },
          details: manufacturer.name,
          line_items: [
            {
              item: create(:item, name: "B Item", value_in_cents: 2000, organization: organization),
              quantity: 1
            }
          ],
          variety: 1,
          quantity: 1,
          total_value: Money.new(2000).to_f
        },
        {
          parameters: {
            issued_at: "2025-03-03",
            source: Donation::SOURCES[:donation_site],
            donation_site: donation_site,
            comment: "comment 3"
          },
          details: donation_site.name,
          line_items: [
            {
              item: create(:item, name: "C Item", value_in_cents: 3000, organization: organization),
              quantity: 2
            }
          ],
          variety: 1,
          quantity: 2,
          total_value: Money.new(6000).to_f
        },
        {
          parameters: {
            issued_at: "2025-04-04",
            source: Donation::SOURCES[:misc],
            comment: "comment 4"
          },
          details: "comment 4",
          line_items: [
            {
              item: create(:item, name: "E Item", value_in_cents: 4000, organization: organization),
              quantity: 3
            }
          ],
          variety: 1,
          quantity: 3,
          total_value: Money.new(12000).to_f
        }
      ]
    }

    let(:donations) do
      expected_donations.each_with_index.map do |expected_don, i|
        donation = create(
          :donation,
          storage_location: storage_location,
          organization: organization,
          **expected_don[:parameters]
        )

        expected_don[:line_items].each do |line_item|
          donation.line_items << create(:line_item, quantity: line_item[:quantity], item: line_item[:item])
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

    let(:expected_item_headers) { ["A Item", "B Item", "C Item", "Dupe Item", "E Item"] }

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      it 'should match the expected content without in-kind value of each item for the csv' do
        expect(subject[0]).to eq(expected_headers)

        expected_donations.zip(expected_items).each_with_index do |(expected_don, expected_item), idx|
          row = [
            expected_don[:parameters][:source],
            expected_don[:parameters][:issued_at],
            expected_don[:details],
            storage_location.name,
            expected_don[:quantity],
            expected_don[:variety],
            expected_don[:total_value],
            expected_don[:parameters][:comment],
            *expected_item.map { |item| item[:quantity] }
          ]

          expect(subject[idx + 1]).to eq(row)
        end
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      let(:expected_item_headers) do
        [
          "A Item", "A Item In-Kind Value",
          "B Item", "B Item In-Kind Value",
          "C Item", "C Item In-Kind Value",
          "Dupe Item", "Dupe Item In-Kind Value",
          "E Item", "E Item In-Kind Value"
        ]
      end
      it 'should match the expected content with in-kind value of each item for the csv' do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)
        expect(subject[0]).to eq(expected_headers)

        expected_donations.zip(expected_items).each_with_index do |(expected_don, expected_item), idx|
          row = [
            expected_don[:parameters][:source],
            expected_don[:parameters][:issued_at],
            expected_don[:details],
            storage_location.name,
            expected_don[:quantity],
            expected_don[:variety],
            expected_don[:total_value],
            expected_don[:parameters][:comment],
            *expected_item.flat_map { |item| [item[:quantity], item[:value]] }
          ]

          expect(subject[idx + 1]).to eq(row)
        end
      end
    end
  end
end
