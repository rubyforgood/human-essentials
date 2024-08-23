RSpec.describe Reports::WarehouseReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization) }
  let(:another_organization) { create(:organization) }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe '#report' do
    it 'should print normal values' do
      create(:storage_location,
        square_footage: 500,
        warehouse_type: 'Residential space used',
        organization: organization)
      create(:storage_location,
        square_footage: 1500,
        warehouse_type: 'Consumer, self-storage or container space',
        organization: organization)
      create(:storage_location,
        square_footage: 1000,
        warehouse_type: 'Warehouse with loading bay',
        organization: organization)
      create(:storage_location,
        square_footage: 2000,
        warehouse_type: 'Warehouse with loading bay',
        organization: another_organization)

      expect(report.report).to eq({
                                    entries: { "Largest storage site type" => "Consumer, self-storage or container space",
                                               "Total square footage" => '3000',
                                               "Total storage locations" => 3 },
                                    name: "Warehouse and Storage"
                                  })
    end

    it 'should print unknown warehouse type' do
      create(:storage_location, square_footage: 500, name: 'Warehouse 1', warehouse_type: nil, organization: organization)
      create(:storage_location, square_footage: 1500, name: 'Warehouse 2', warehouse_type: nil, organization: organization)
      create(:storage_location, square_footage: 1000, name: 'Warehouse 3', warehouse_type: nil, organization: organization)
      create(:storage_location, square_footage: 2000, organization: another_organization)

      expect(report.report).to eq({
                                    entries: { "Largest storage site type" => "Warehouse 2 - warehouse type not given",
                                               "Total square footage" => '3000',
                                               "Total storage locations" => 3 },
                                    name: "Warehouse and Storage"
                                  })
    end

    it 'should print zero values' do
      expect(report.report).to eq({
                                    entries: { "Largest storage site type" => "No warehouses with square footage entered",
                                               "Total square footage" => "0",
                                               "Total storage locations" => 0 },
                                    name: "Warehouse and Storage"
                                  })
    end

    it 'should print unknown square footage' do
      create(:storage_location,
        square_footage: 500,
        warehouse_type: 'Residential space used',
        organization: organization)
      create(:storage_location,
        square_footage: nil,
        warehouse_type: 'Consumer, self-storage or container space',
        organization: organization)
      create(:storage_location,
        square_footage: nil,
        warehouse_type: 'Warehouse with loading bay',
        organization: organization)

      expect(report.report).to eq({
                                    entries: { "Largest storage site type" => "Residential space used",
                                               "Total square footage" => "500 (2 locations do not have square footage entered)",
                                               "Total storage locations" => 3 },
                                    name: "Warehouse and Storage"
                                  })
    end
  end
end
