RSpec.describe Exports::ExportDistributionsCSVService do
  let(:organization) { create(:organization, include_in_kind_values_in_exported_files: include_in_kind_values, include_packages_in_distribution_export: include_packages) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:partner) { create(:partner, name: "first partner", email: "firstpartner@gmail.com", notes: "just a note.", organization_id: organization.id) }
  let(:include_in_kind_values) { false }
  let(:include_packages) { false }

  describe '#generate_csv' do
    subject { described_class.new(distributions: distributions, organization: organization, filters: filters).generate_csv }

    let(:duplicate_item) { create(:item, name: "Dupe Item", value_in_cents: 300, organization: organization, package_size: 2) }

    let(:distribution_items_and_quantities) {
      [
        [
          [duplicate_item, 5],
          [create(:item, name: "A Item", value_in_cents: 1000, organization: organization, package_size: 6), 7],
          [duplicate_item, 3]
        ],
        [[create(:item, name: "B Item", value_in_cents: 2000, organization: organization), 1]],
        [[create(:item, name: "C Item", value_in_cents: 3000, organization: organization), 2]],
        [[create(:item, name: "E Item", value_in_cents: 4000, organization: organization), 3]]
      ]
    }

    let(:distributions) do
      distribution_items_and_quantities.each_with_index.map do |dist, i|
        distribution = create(
          :distribution,
          partner: partner,
          organization: organization,
          storage_location: storage_location,
          created_at: "04/04/2025",
          issued_at: "04/04/2025",
          delivery_method: "shipped",
          shipping_cost: "15.01",
          state: "scheduled",
          agency_rep: "",
          comment: "comment #{i}"
        )

        dist.each do |line_item|
          distribution.line_items << create(:line_item, item: line_item[0], quantity: line_item[1])
        end

        distribution
      end
    end

    let(:item_id) { duplicate_item.id }
    let(:item_name) { duplicate_item.name }
    let(:filters) { {by_item_id: item_id} }

    context 'while both in-kind values and package count are disabled for export' do
      it 'should match the expected content without in-kind value or package count for each item for the csv' do
        csv = <<~CSV
          Partner,Initial Allocation,Scheduled for,Source Inventory,Total Number of #{item_name},Total Value of #{item_name},Delivery Method,Shipping Cost,Status,Agency Representative,Comments,A Item,B Item,C Item,Dupe Item,E Item
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},8,24.0,shipped,$15.01,scheduled,"",comment 0,7,0,0,8,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 1,0,1,0,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 2,0,0,2,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 3,0,0,0,0,3
        CSV
        expect(subject).to eq(csv)
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      let(:include_in_kind_values) { true }

      it 'should match the expected content with in-kind value of each item for the csv' do
        csv = <<~CSV
          Partner,Initial Allocation,Scheduled for,Source Inventory,Total Number of #{item_name},Total Value of #{item_name},Delivery Method,Shipping Cost,Status,Agency Representative,Comments,A Item,A Item In-Kind Value,B Item,B Item In-Kind Value,C Item,C Item In-Kind Value,Dupe Item,Dupe Item In-Kind Value,E Item,E Item In-Kind Value
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},8,24.0,shipped,$15.01,scheduled,"",comment 0,7,70.00,0,0.00,0,0.00,8,24.00,0,0.00
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 1,0,0.00,1,20.00,0,0.00,0,0.00,0,0.00
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 2,0,0.00,0,0.00,2,60.00,0,0.00,0,0.00
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 3,0,0.00,0,0.00,0,0.00,0,0.00,3,120.00
        CSV
        expect(subject).to eq(csv)
      end
    end

    context 'while "Include packages in distribution export" is set to yes' do
      let(:include_packages) { true }

      it 'should match the expected content with package count of each item for the csv' do
        csv = <<~CSV
          Partner,Initial Allocation,Scheduled for,Source Inventory,Total Number of #{item_name},Total Value of #{item_name},Delivery Method,Shipping Cost,Status,Agency Representative,Comments,A Item,A Item Packages,B Item,B Item Packages,C Item,C Item Packages,Dupe Item,Dupe Item Packages,E Item,E Item Packages
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},8,24.0,shipped,$15.01,scheduled,"",comment 0,7,1.17,0,0,0,0,8,4.0,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 1,0,0,1,0,0,0,0,0,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 2,0,0,0,0,2,0,0,0,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 3,0,0,0,0,0,0,0,0,3,0
        CSV
        expect(subject).to eq(csv)
      end
    end

    context 'while both in-kind values and package count are enabled for export' do
      let(:include_in_kind_values) { true }
      let(:include_packages) { true }

      it 'should match the expected content with in-kind value and package count of each item for the csv' do
        csv = <<~CSV
          Partner,Initial Allocation,Scheduled for,Source Inventory,Total Number of #{item_name},Total Value of #{item_name},Delivery Method,Shipping Cost,Status,Agency Representative,Comments,A Item,A Item In-Kind Value,A Item Packages,B Item,B Item In-Kind Value,B Item Packages,C Item,C Item In-Kind Value,C Item Packages,Dupe Item,Dupe Item In-Kind Value,Dupe Item Packages,E Item,E Item In-Kind Value,E Item Packages
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},8,24.0,shipped,$15.01,scheduled,"",comment 0,7,70.00,1.17,0,0.00,0,0,0.00,0,8,24.00,4.0,0,0.00,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 1,0,0.00,0,1,20.00,0,0,0.00,0,0,0.00,0,0,0.00,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 2,0,0.00,0,0,0.00,0,2,60.00,0,0,0.00,0,0,0.00,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 3,0,0.00,0,0,0.00,0,0,0.00,0,0,0.00,0,3,120.00,0
        CSV
        expect(subject).to eq(csv)
      end
    end

    context 'when a new item is added' do
      let(:new_item_name) { "New Item" }
      let(:original_columns_count) { 15 }
      before do
        # if distributions are not created before new item
        # then additional records will be created
        distributions
        create(:item, name: new_item_name, organization: organization)
      end

      it 'should add it to the end of the row and show up with a 0 quantity if there are none of this item in any distribution' do
        csv = <<~CSV
          Partner,Initial Allocation,Scheduled for,Source Inventory,Total Number of #{item_name},Total Value of #{item_name},Delivery Method,Shipping Cost,Status,Agency Representative,Comments,A Item,B Item,C Item,Dupe Item,E Item,New Item
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},8,24.0,shipped,$15.01,scheduled,"",comment 0,7,0,0,8,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 1,0,1,0,0,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 2,0,0,2,0,0,0
          #{partner.name},04/04/2025,04/04/2025,#{storage_location.name},0,0.0,shipped,$15.01,scheduled,"",comment 3,0,0,0,0,3,0
        CSV
        expect(subject).to eq(csv)
      end
    end

    context 'when there are no distributions but the report is requested' do
      subject { described_class.new(distributions: [], organization: organization, filters: filters).generate_csv }
      it 'returns a csv with only headers and no rows' do
        csv = <<~CSV
          Partner,Initial Allocation,Scheduled for,Source Inventory,Total Number of #{item_name},Total Value of #{item_name},Delivery Method,Shipping Cost,Status,Agency Representative,Comments,Dupe Item
        CSV
        expect(subject).to eq(csv)
      end
    end
  end
end
