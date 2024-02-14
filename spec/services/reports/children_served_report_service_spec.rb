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

      # Kits
      kit = create(:kit, :with_item, organization: organization)

      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers", kit: kit)
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers", kit: kit)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, :distribution, quantity: 10, item: toddler_disposable_kit_item, itemizable: infant_distribution)
      create(:line_item, :distribution, quantity: 10, item: infant_disposable_kit_item, itemizable: toddler_distribution)

      expect(report.report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "8",
                                      'Total children served' => "101",
                                      'Diapers per child monthly' => "25",
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
      # Kits
      kit = create(:kit, :with_item, organization: organization)

      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers", kit: kit)
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers", kit: kit)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, :distribution, quantity: 10, item: toddler_disposable_kit_item, itemizable: infant_distribution)
      create(:line_item, :distribution, quantity: 10, item: infant_disposable_kit_item, itemizable: toddler_distribution)

      expect(report.report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "3",
                                      'Total children served' => "41",
                                      'Diapers per child monthly' => "50",
                                      'Repackages diapers?' => 'Y',
                                      'Monthly diaper distributions?' => 'Y'
                                    }
                                  })
    end
  end
end
