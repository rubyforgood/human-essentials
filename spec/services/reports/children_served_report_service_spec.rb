RSpec.describe Reports::ChildrenServedReportService, type: :service do
  let(:year) { 2020 }
  let(:within_time) { Time.zone.parse("2020-05-31 14:00:00") }
  let(:outside_time) { Time.zone.parse("2019-05-31 14:00:00") }

  describe '#report' do
    it 'should report zero values' do
      organization = create(:organization)
      report = described_class.new(organization: organization, year: year).report
      expect(report).to eq({
        name: 'Children Served',
        entries: {
          'Average children served monthly' => "0.0",
          'Total children served' => "0",
          'Repackages diapers?' => 'N',
          'Monthly diaper distributions?' => 'N'
        }
      })
    end

    it 'should report normal values' do
      organization = create(:organization, :with_items, distribute_monthly: true, repackage_essentials: true)

      disposable_item = organization.items.disposable.first
      disposable_item.update!(distribution_quantity: 20)
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # Kits
      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers")
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers")

      kit_1 = create(:kit, organization: organization, line_items: [
        create(:line_item, item: toddler_disposable_kit_item),
        create(:line_item, item: infant_disposable_kit_item)
      ])

      kit_2 = create(:kit, organization: organization, line_items: [
        create(:line_item, item: toddler_disposable_kit_item),
        create(:line_item, item: infant_disposable_kit_item)
      ])

      create(:item, name: "Kit 1", kit: kit_1, organization:)
      create(:item, name: "Kit 2", kit: kit_2, organization:)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, quantity: 5, item: kit_1.item, itemizable: infant_distribution)
      create(:line_item, quantity: 5, item: kit_1.item, itemizable: toddler_distribution)
      create(:line_item, quantity: 5, item: kit_2.item, itemizable: infant_distribution)
      create(:line_item, quantity: 5, item: kit_2.item, itemizable: toddler_distribution)

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
        name: 'Children Served',
        entries: {
          'Average children served monthly' => "10.0",
          'Total children served' => "120", # 100 normal and 20 from kits
          'Repackages diapers?' => 'Y',
          'Monthly diaper distributions?' => 'Y'
        }
      })
    end

    it 'should work with no distribution_quantity' do
      organization = create(:organization, :with_items, distribute_monthly: true, repackage_essentials: true)

      within_time = Time.zone.parse("2020-05-31 14:00:00")
      outside_time = Time.zone.parse("2019-05-31 14:00:00")

      disposable_item = organization.items.disposable.first
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # Kits
      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers")
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers")

      kit = create(:kit, organization: organization, line_items: [
        create(:line_item, item: toddler_disposable_kit_item),
        create(:line_item, item: infant_disposable_kit_item)
      ])

      create(:item, name: "Kit 1", kit:, organization:)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, quantity: 10, item: kit.item, itemizable: infant_distribution)
      create(:line_item, quantity: 10, item: kit.item, itemizable: toddler_distribution)

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
        name: 'Children Served',
        entries: {
          'Average children served monthly' => "5.0",
          'Total children served' => "60", # 40 normal and 20 from kits
          'Repackages diapers?' => 'Y',
          'Monthly diaper distributions?' => 'Y'
        }
      })
    end

    it "rounds children served to integer ceiling" do
      organization = create(:organization, :with_items)

      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")
      create(:base_item, name: "Adult Diaper", partner_key: "adult diapers", category: "adult diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers")
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers")
      not_disposable_kit_item = create(:item, name: "Adult Diapers", partner_key: "adult diapers")

      # this quantity shouldn't matter so I'm setting it to a high number to ensure it isn't used
      kit = create(:kit, organization: organization, line_items: [
        create(:line_item, quantity: 1000, item: toddler_disposable_kit_item),
        create(:line_item, quantity: 1000, item: infant_disposable_kit_item),
        create(:line_item, quantity: 1000, item: not_disposable_kit_item)
      ])

      create(:item, name: "Kit 1", kit:, organization:, distribution_quantity: 3)

      # Distributions
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)
      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)

      [toddler_distribution, infant_distribution].each do |distribution|
        create(:line_item, quantity: 2, item: kit.item, itemizable: distribution)
      end

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
        name: "Children Served",
        entries: {
          "Average children served monthly" => "0.17",
          "Total children served" => "2", # 2 kits / 3 distribution_quantity = 1 child served * 2 distributions = 2
          "Repackages diapers?" => "N",
          "Monthly diaper distributions?" => "N"
        }
      })
    end
  end
end
