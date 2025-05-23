RSpec.describe Exports::ExportDonationsCSVService do
  describe '#generate_csv' do
    let(:organization) { create(:organization) }
    let(:storage_location) { create(:storage_location, organization: organization) }

    subject { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv }
    let(:donation_ids) { donations.map(&:id) }
    let(:duplicate_item) { create(:item, name: "Dupe Item", value_in_cents: 300, organization: organization) }

    let(:donation_items_and_quantities) {
      [
        {
          source: :product_drive_donation,
          items: [
            [duplicate_item, 5],
            [create(:item, name: "A Item", value_in_cents: 1000, organization: organization), 7],
            [duplicate_item, 3]
          ]
        },
        {
          source: :manufacturer_donation,
          items: [[create(:item, name: "B Item", value_in_cents: 2000, organization: organization), 1]]
        },
        {
          source: :donation_site_donation,
          items: [[create(:item, name: "C Item", value_in_cents: 3000, organization: organization), 2]]
        },
        {
          source: :donation,
          items: [[create(:item, name: "E Item", value_in_cents: 4000, organization: organization), 3]]
        }
      ]
    }

    let(:donations) do
      donation_items_and_quantities.each_with_index.map do |items_quantities, i|
        donation = create(
          items_quantities[:source],
          storage_location: storage_location,
          organization: organization,
          issued_at: "2025-01-01"
        )

        items_quantities[:items].each do |line_item|
          donation.line_items << create(:line_item, item: line_item[0], quantity: line_item[1])
        end

        donation
      end
    end

    def source_name(donation)
      if !donation.product_drive.nil?
        donation.product_drive.name
      elsif !donation.manufacturer.nil?
        donation.manufacturer.name
      elsif !donation.donation_site.nil?
        donation.donation_site.name
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      it 'should match the expected content without in-kind value of each item for the csv' do
        csv = <<~CSV
          Source,Date,Details,Storage Location,Quantity of Items,Variety of Items,In-Kind Total,Comments,A Item,B Item,C Item,Dupe Item,E Item
          Product Drive,2025-01-01,#{source_name(donations[0])},#{storage_location.name},15,2,94.0,It's a fine day for diapers.,7,0,0,8,0
          Manufacturer,2025-01-01,#{source_name(donations[1])},#{storage_location.name},1,1,20.0,It's a fine day for diapers.,0,1,0,0,0
          Donation Site,2025-01-01,#{source_name(donations[2])},#{storage_location.name},2,1,60.0,It's a fine day for diapers.,0,0,2,0,0
          Misc. Donation,2025-01-01,It's a fine day for...,#{storage_location.name},3,1,120.0,It's a fine day for diapers.,0,0,0,0,3
        CSV
        expect(subject).to eq(csv)
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      it 'should match the expected content with in-kind value of each item for the csv' do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)

        csv = <<~CSV
          Source,Date,Details,Storage Location,Quantity of Items,Variety of Items,In-Kind Total,Comments,A Item,A Item In-Kind Value,B Item,B Item In-Kind Value,C Item,C Item In-Kind Value,Dupe Item,Dupe Item In-Kind Value,E Item,E Item In-Kind Value
          Product Drive,2025-01-01,#{source_name(donations[0])},#{storage_location.name},15,2,94.0,It's a fine day for diapers.,7,70.00,0,0.00,0,0.00,8,24.00,0,0.00
          Manufacturer,2025-01-01,#{source_name(donations[1])},#{storage_location.name},1,1,20.0,It's a fine day for diapers.,0,0.00,1,20.00,0,0.00,0,0.00,0,0.00
          Donation Site,2025-01-01,#{source_name(donations[2])},#{storage_location.name},2,1,60.0,It's a fine day for diapers.,0,0.00,0,0.00,2,60.00,0,0.00,0,0.00
          Misc. Donation,2025-01-01,It's a fine day for...,#{storage_location.name},3,1,120.0,It's a fine day for diapers.,0,0.00,0,0.00,0,0.00,0,0.00,3,120.00
        CSV
        expect(subject).to eq(csv)
      end
    end
  end
end
