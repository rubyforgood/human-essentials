RSpec.describe Reports::ChildrenServedReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization) }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe '#report' do
    it 'should report zero values' do
      expect(report.report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "0",
                                      'Total children served' => "0",
                                      'Diapers per child monthly' => "0",
                                      'Repackages diapers?' => 'N',
                                      'Monthly diaper distributions?' => 'N'
                                    }
                                  })
    end

    it 'should report normal values' do
      Organization.seed_items(organization)
      organization.update!(distribute_monthly: true, repackage_essentials: true)

      within_time = Time.zone.parse("2020-05-31 14:00:00")
      outside_time = Time.zone.parse("2019-05-31 14:00:00")

      disposable_item = organization.items.disposable.first
      disposable_item.update!(distribution_quantity: 20)
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      # Kits
      kits = create_list(:kit, 2, organization: organization)
      kits.each do |kit|
        disposable_kit_item = create(:item, name: "Disposables #{kit.id}", organization: organization, kit: kit)
        storage_location = create(:storage_location, organization: organization)
        create(:inventory_item, quantity: 10, item: disposable_kit_item, storage_location: storage_location)
      end

      expect(report.report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "9",
                                      'Total children served' => "102",
                                      'Diapers per child monthly' => "15",
                                      'Repackages diapers?' => 'Y',
                                      'Monthly diaper distributions?' => 'Y'
                                    }
                                  })
    end

    it 'should work with no distribution_quantity' do
      Organization.seed_items(organization)
      organization.update!(distribute_monthly: true, repackage_essentials: true)

      within_time = Time.zone.parse("2020-05-31 14:00:00")
      outside_time = Time.zone.parse("2019-05-31 14:00:00")

      disposable_item = organization.items.disposable.first
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      # Kits
      kits = create_list(:kit, 2, organization: organization)
      kits.each do |kit|
        disposable_kit_item = create(:item, name: "Disposables #{kit.id}", organization: organization, kit: kit)
        storage_location = create(:storage_location, organization: organization)
        create(:inventory_item, quantity: 10, item: disposable_kit_item, storage_location: storage_location)
      end

      expect(report.report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "4",
                                      'Total children served' => "42",
                                      'Diapers per child monthly' => "30",
                                      'Repackages diapers?' => 'Y',
                                      'Monthly diaper distributions?' => 'Y'
                                    }
                                  })
    end
  end
end
