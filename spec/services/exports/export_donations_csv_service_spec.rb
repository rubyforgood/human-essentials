RSpec.describe Exports::ExportDonationsCSVService do
  describe '#generate_csv' do
    let(:organization) { create(:organization) }
    let(:storage_location) { create(:storage_location, organization: organization, name: "Test Storage Location") }

    subject { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv }
    let(:donation_ids) { donations.map(&:id) }
    let(:duplicate_item) { create(:item, name: "Dupe Item", value_in_cents: 300, organization: organization) }

    let(:donation_definitions) {
      [
        {
          factory: :product_drive_donation,
          attributes: {product_drive: create(:product_drive, name: "Test Product Drive", organization: organization)},
          items: [
            [duplicate_item, 5],
            [create(:item, name: "A Item", value_in_cents: 1000, organization: organization), 7],
            [duplicate_item, 3]
          ]
        },
        {
          factory: :manufacturer_donation,
          attributes: {manufacturer: create(:manufacturer, name: "Test Manufacturer", organization: organization)},
          items: [[create(:item, name: "B Item", value_in_cents: 2000, organization: organization), 1]]
        },
        {
          factory: :donation_site_donation,
          attributes: {donation_site: create(:donation_site, name: "Test Donation Site", organization: organization)},
          items: [[create(:item, name: "C Item", value_in_cents: 3000, organization: organization), 2]]
        },
        {
          factory: :donation,
          attributes: {},
          items: [[create(:item, name: "E Item", value_in_cents: 4000, organization: organization), 3]]
        }
      ]
    }

    let(:donations) do
      donation_definitions.map do |definition|
        donation = create(
          definition[:factory],
          storage_location: storage_location,
          organization: organization,
          issued_at: "2025-01-01",
          comment: "It's a fine day for diapers.",
          **definition[:attributes]
        )

        definition[:items].each do |(item, quantity)|
          donation.line_items << create(:line_item, item: item, quantity: quantity)
        end

        donation
      end
    end

    def expected_csv(fixture_name)
      Rails.root.join("spec/fixtures/files", fixture_name).read
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      it 'should match the expected content without in-kind value of each item for the csv' do
        expect(subject).to eq(expected_csv("donations_export.csv"))
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      before do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)
      end

      it 'should match the expected content with in-kind value of each item for the csv' do
        expect(subject).to eq(expected_csv("donations_export_with_in_kind_values.csv"))
      end

      it 'should include inactive items in the export with zero quantities' do
        create(:item, :inactive, name: "Inactive Item", organization: organization)

        expect(subject).to eq(expected_csv("donations_export_with_inactive_item.csv"))
      end

      it 'should include items that are not in any donation with zero quantities' do
        create(:item, name: "Unused Item", organization: organization)

        expect(subject).to eq(expected_csv("donations_export_with_unused_item.csv"))
      end
    end

    context 'when item names differ only by case' do
      let(:donation_definitions) {
        [
          {
            factory: :donation,
            attributes: {},
            items: [[create(:item, name: "Banana", value_in_cents: 150, organization: organization), 2]]
          }
        ]
      }

      it 'should sort item columns case-insensitively, ASC' do
        # Create the other items in reverse-ASCII order to prove the sort is
        # case-insensitive rather than relying on creation order or ASCII order
        # (which would put "Zebra" before "apple").
        create(:item, name: "apple", organization: organization)
        create(:item, name: "Zebra", organization: organization)

        expect(subject).to eq(expected_csv("donations_export_case_insensitive_sort.csv"))
      end
    end
  end
end
