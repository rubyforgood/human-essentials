RSpec.describe Reports::ChildrenServedReportService, type: :service do
  let(:year) { 2020 }

  describe '#report' do
    it 'should report zero values' do
      organization = create(:organization)
      report = described_class.new(organization: organization, year: year).report
      expect(report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "0",
                                      'Total children served' => "0",
                                      'Repackages diapers?' => 'N',
                                      'Monthly diaper distributions?' => 'N'
                                    }
                                  })
    end

    it 'should report normal values' do
      organization = create(:organization, :with_items, distribute_monthly: true, repackage_essentials: true)

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

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "8",
                                      'Total children served' => "101",
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

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
                                    name: 'Children Served',
                                    entries: {
                                      'Average children served monthly' => "3",
                                      'Total children served' => "41",
                                      'Repackages diapers?' => 'Y',
                                      'Monthly diaper distributions?' => 'Y'
                                    }
                                  })
    end
  end
  describe "#disposable_diapers_from_kits_total" do
    it "calculates the number of disposable diapers that have been distributed within kits this year" do
      organization = create(:organization)

      # create disposable/ nondisposable base items
      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")
      create(:base_item, name: "Infant Cloth Diaper", partner_key: "infant cloth diapers", category: "cloth diaper")
      create(:base_item, name: "Adult Brief LXL Test", partner_key: "adult lxl test", category: "Diapers - Adult Briefs")

      # create disposable/ nondisposable items
      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", organization: organization)
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers", organization: organization)
      infant_cloth_kit_item = create(:item, name: "Infant Cloth Diapers", partner_key: "infant cloth diapers", organization: organization)
      adult_brief_kit_item = create(:item, name: "Adult Brief L/XL", partner_key: "adult lxl test", organization: organization)

      # create line items that contain the d/nd items
      toddler_disposable_line_item = create(:line_item, item: toddler_disposable_kit_item, quantity: 5)
      infant_disposable_line_item = create(:line_item, item: infant_disposable_kit_item, quantity: 5)
      infant_cloth_line_item = create(:line_item, item: infant_cloth_kit_item, quantity: 5)
      adult_brief_line_item = create(:line_item, item: adult_brief_kit_item, quantity: 5)

      # create kits that contain the d/nd line items
      toddler_disposable_kit = create(:kit, organization: organization, line_items: [toddler_disposable_line_item])
      infant_disposable_kit = create(:kit, organization: organization, line_items: [infant_disposable_line_item])
      infant_cloth_kit = create(:kit, organization: organization, line_items: [infant_cloth_line_item])
      adult_brief_kit = create(:kit, organization: organization, line_items: [adult_brief_line_item])

      # create items which have the kits
      create(:base_item, name: "Unrelated Base", partner_key: "unrelated base", category: "unrelated base")
      infant_disposable_dist_item = create(:item, name: "Dist Item 1", organization: organization, partner_key: "unrelated base", kit: toddler_disposable_kit)
      toddler_disposable_dist_item = create(:item, name: "Dist Item 2", organization: organization, partner_key: "unrelated base", kit: infant_disposable_kit)
      infant_cloth_dist_item = create(:item, name: "Dist Item 3", organization: organization, partner_key: "unrelated base", kit: infant_cloth_kit)
      adult_brief_dist_item = create(:item, name: "Dist Item 4", organization: organization, partner_key: "unrelated base", kit: adult_brief_kit)

      within_time = Time.zone.parse("2020-05-31 14:00:00")

      # create empty distributions
      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)
      adult_distribution = create(:distribution, organization: organization, issued_at: within_time)

      # add line items to distributions which contain the d/nd kits
      create(:line_item, quantity: 10, item: toddler_disposable_dist_item, itemizable: toddler_distribution)
      create(:line_item, quantity: 10, item: infant_disposable_dist_item, itemizable: infant_distribution)
      create(:line_item, quantity: 10, item: infant_cloth_dist_item, itemizable: infant_distribution)
      create(:line_item, quantity: 10, item: adult_brief_dist_item, itemizable: adult_distribution)

      service = described_class.new(organization: organization, year: within_time.year)

      # Find distributions, that has a
      # Line item, that has an
      # Item, which has a
      # Kit, which has a
      # Line item, which has an
      # Item, which is a disposable diaper.
      # And then add all those quantities up
      expect(service.disposable_diapers_from_kits_total).to eq(100)
    end
  end
end
