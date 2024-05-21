RSpec.describe Reports::OtherProductsReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization, :with_items) }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe '#report' do
    it 'should report zero values' do
      expect(report.report).to eq({
                                    entries: {
                                      'Other products distributed' => '0',
                                      '% other products donated' => "0%",
                                      '% other products bought' => "0%",
                                      'Money spent on other products' => '$0.00',
                                      'List of other products' => organization.items.other_categories.map(&:name).sort.uniq.join(', ')
                                    },
                                    name: "Other Items"
                                  })
    end

    it 'should report normal values' do
      within_time = Time.zone.parse("2020-05-31 14:00:00")
      outside_time = Time.zone.parse("2019-05-31 14:00:00")

      other_item = organization.items.other_categories.first
      non_other_item = organization.items.where.not(id: organization.items.other_categories).first

      # We will create data both within and outside our date range, and both adult_incontinence and non adult_incontinence.
      # Spec will ensure that only the required data is included.

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 20, item: other_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 30, item: non_other_item, itemizable: dist)
      end

      # Donations
      donations = create_list(:donation, 2,
                              issued_at: within_time,
                              money_raised: 1000,
                              organization: organization)

      donations += create_list(:donation, 2,
                               issued_at: outside_time,
                               money_raised: 1000,
                               organization: organization)

      donations.each do |donation|
        create_list(:line_item, 3, :donation, quantity: 20, item: other_item, itemizable: donation)
        create_list(:line_item, 3, :donation, quantity: 10, item: non_other_item, itemizable: donation)
      end

      # Purchases
      purchases = [
        create(:purchase,
               issued_at: within_time,
               organization: organization,
               amount_spent_in_cents: 1000,
               amount_spent_on_other_cents: 1000),
        create(:purchase,
               issued_at: within_time,
               organization: organization,
               amount_spent_in_cents: 2000,
               amount_spent_on_other_cents: 2000),
      ]
      purchases += create_list(:purchase, 2,
                               issued_at: outside_time,
                               amount_spent_in_cents: 20_000,
                               amount_spent_on_other_cents: 20_000,
                               organization: organization)
      purchases.each do |purchase|
        create_list(:line_item, 3, :purchase, quantity: 30, item: other_item, itemizable: purchase)
        create_list(:line_item, 3, :purchase, quantity: 40, item: non_other_item, itemizable: purchase)
      end

      expect(report.report).to eq({
                                    entries: {
                                      'Other products distributed' => '200',
                                      '% other products donated' => "40%",
                                      '% other products bought' => "60%",
                                      'Money spent on other products' => '$30.00',
                                      'List of other products' => organization.items.other_categories.map(&:name).sort.uniq.join(', ')
                                    },
                                    name: "Other Items"
                                  })
    end
  end
end
