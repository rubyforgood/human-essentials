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
      before do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)
      end

      it 'should match the expected content with in-kind value of each item for the csv' do
        csv = <<~CSV
          Source,Date,Details,Storage Location,Quantity of Items,Variety of Items,In-Kind Total,Comments,A Item,A Item In-Kind Value,B Item,B Item In-Kind Value,C Item,C Item In-Kind Value,Dupe Item,Dupe Item In-Kind Value,E Item,E Item In-Kind Value
          Product Drive,2025-01-01,#{source_name(donations[0])},#{storage_location.name},15,2,94.0,It's a fine day for diapers.,7,70.00,0,0.00,0,0.00,8,24.00,0,0.00
          Manufacturer,2025-01-01,#{source_name(donations[1])},#{storage_location.name},1,1,20.0,It's a fine day for diapers.,0,0.00,1,20.00,0,0.00,0,0.00,0,0.00
          Donation Site,2025-01-01,#{source_name(donations[2])},#{storage_location.name},2,1,60.0,It's a fine day for diapers.,0,0.00,0,0.00,2,60.00,0,0.00,0,0.00
          Misc. Donation,2025-01-01,It's a fine day for...,#{storage_location.name},3,1,120.0,It's a fine day for diapers.,0,0.00,0,0.00,0,0.00,0,0.00,3,120.00
        CSV
        expect(subject).to eq(csv)
      end

      it 'should include inactive items in the export' do
        inactive_item = create(:item, :inactive, name: "Inactive Item", organization: organization)
        csv_data = described_class.new(donation_ids: donation_ids, organization: organization).generate_csv_data

        # Verify the inactive item appears in headers
        expect(csv_data[0]).to include(inactive_item.name)
        expect(csv_data[0]).to include("#{inactive_item.name} In-Kind Value")

        # Verify all rows have 0 quantity for the inactive item
        inactive_item_index = csv_data[0].index(inactive_item.name)
        csv_data[1..].each do |row|
          expect(row[inactive_item_index]).to eq(0)
          expect(row[inactive_item_index + 1]).to eq(0)
        end
      end

      it 'should include items that are not in any donation' do
        unused_item = create(:item, name: "Unused Item", organization: organization)
        csv_data = described_class.new(donation_ids: donation_ids, organization: organization).generate_csv_data

        # Verify the unused item appears in headers
        expect(csv_data[0]).to include(unused_item.name)
        expect(csv_data[0]).to include("#{unused_item.name} In-Kind Value")

        # Verify all rows have 0 quantity for the unused item
        unused_item_index = csv_data[0].index(unused_item.name)
        csv_data[1..].each do |row|
          expect(row[unused_item_index]).to eq(0)
          expect(row[unused_item_index + 1]).to eq(0)
        end
      end
    end
  end

  describe '#generate_csv_data' do
    let(:organization) { create(:organization) }
    let(:generated_csv_data) { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv_data }
    let(:donation_ids) { donations.map(&:id) }
    let(:duplicate_item) { create(:item, organization: organization) }
    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [create(:item, organization: organization), 7],
          [duplicate_item, 3]
        ],
        *(Array.new(3) do |i|
          [[create(
            :item, name: "item_#{i}", organization: organization
          ), i + 1]]
        end)
      ]
    end

    let(:base_headers) do
      described_class.new(donation_ids: [], organization: organization).send(:base_headers)
    end

    let(:item_names) { items_lists.flatten(1).map(&:first).map(&:name).sort.uniq }

    let(:donations) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        donation = create(
          :donation,
          organization: organization,
          donation_site: create(
            :donation_site, name: "Space Needle #{i}", organization: organization
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

    it 'should match the expected content for the csv' do
      expect(generated_csv_data[0]).to eq(expected_headers)

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

        expect(generated_csv_data[idx + 1]).to eq(row)
      end
    end

    context 'when an organization\'s item exists but isn\'t in any donation' do
      let(:unused_item) { create(:item, name: "Unused Item", organization: organization) }
      let(:generated_csv_data) do
        # Force unused_item to be created first
        unused_item
        described_class.new(donation_ids: donations.map(&:id), organization: organization).generate_csv_data
      end

      it 'should include the unused item as a column with 0 quantities' do
        expect(generated_csv_data[0]).to include(unused_item.name)

        donations.each_with_index do |_, idx|
          row = generated_csv_data[idx + 1]
          item_column_index = generated_csv_data[0].index(unused_item.name)
          expect(row[item_column_index]).to eq(0)
        end
      end
    end

    context 'when an organization\'s item is inactive' do
      let(:inactive_item) { create(:item, name: "Inactive Item", organization: organization, active: false) }
      let(:generated_csv_data) do
        # Force inactive_item to be created first
        inactive_item
        described_class.new(donation_ids: donations.map(&:id), organization: organization).generate_csv_data
      end

      it 'should include the inactive item as a column with 0 quantities' do
        expect(generated_csv_data[0]).to include(inactive_item.name)

        donations.each_with_index do |_, idx|
          row = generated_csv_data[idx + 1]
          item_column_index = generated_csv_data[0].index(inactive_item.name)
          expect(row[item_column_index]).to eq(0)
        end
      end
    end

    context 'when generating CSV output' do
      let(:generated_csv) { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv }

      it 'returns a valid CSV string' do
        expect(generated_csv).to be_a(String)
        expect { CSV.parse(generated_csv) }.not_to raise_error
      end

      it 'includes headers as first row' do
        csv_rows = CSV.parse(generated_csv)
        expect(csv_rows.first).to eq(expected_headers)
      end

      it 'includes data for all donations' do
        csv_rows = CSV.parse(generated_csv)
        expect(csv_rows.count).to eq(donations.count + 1) # +1 for headers
      end
    end

    context 'when items have different cases' do
      let(:item_names) { ["Zebra", "apple", "Banana"] }
      let(:expected_order) { ["apple", "Banana", "Zebra"] }
      let(:donation) { create(:donation, organization: organization) }
      let(:case_sensitive_csv_data) do
        # Create items in random order to ensure sort is working
        item_names.shuffle.each do |name|
          create(:item, name: name, organization: organization)
        end

        described_class.new(donation_ids: [donation.id], organization: organization).generate_csv_data
      end

      it 'should sort item columns case-insensitively, ASC' do
        # Get just the item columns by removing the known base headers
        item_columns = case_sensitive_csv_data[0] - base_headers

        # Check that the remaining columns match our expected case-insensitive sort
        expect(item_columns).to eq(expected_order)
      end
    end
  end
end
