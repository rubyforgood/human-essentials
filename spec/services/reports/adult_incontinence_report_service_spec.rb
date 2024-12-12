RSpec.describe Reports::AdultIncontinenceReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization, :with_items) }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe '#report' do
    it 'should report zero values' do
      expect(report.report[:name]).to eq("Adult Incontinence")
      expect(report.report[:entries]).to match(hash_including({
                                      "Adult incontinence supplies distributed" => "0",
                                      "Adults Assisted Per Month" => 0,
                                      "% adult incontinence bought" => "0%",
                                      "% adult incontinence supplies donated" => "0%",
                                      "Adult incontinence supplies per adult per month" => 0,
                                      "Money spent purchasing adult incontinence supplies" => "$0.00"
                                  }))
      expect(report.report[:entries]['Adult incontinence supplies'].split(', '))
        .to contain_exactly("Adult Briefs (Large/X-Large)",
                           "Adult Briefs (Medium/Large)",
                           "Adult Briefs (Small/Medium)",
                           "Adult Briefs (XXL)",
                           "Adult Briefs (XXXL)",
                           "Adult Briefs (XS/Small)",
                           "Adult Briefs (XXS)",
                           "Adult Incontinence Pads",
                            "Liners (Incontinence)",
                           "Underpads (Pack)",
                            "Adult Cloth Diapers (Large/XL/XXL)",
                            "Adult Cloth Diapers (Small/Medium)")
    end

    describe 'with values' do
      before(:each) do
        within_time = Time.zone.parse("2020-05-31 14:00:00")
        outside_time = Time.zone.parse("2019-05-31 14:00:00")

        adult_incontinence_item = organization.items.adult_incontinence.first
        non_adult_incontinence_item = organization.items.where.not(id: organization.items.adult_incontinence).first

        # kits
        kit_1 = create(:kit, organization: organization)
        kit_2 = create(:kit, organization: organization)

        create(:base_item, name: "Adult Pads", partner_key: "adult pads", category: "adult pads")
        create(:base_item, name: "Adult wipes", partner_key: "adult wipes", category: "adult wipes")

        adult_kit_item_1 = create(:item, name: "Adult Pads", partner_key: "adult pads", kit: kit_1)
        adult_kit_item_2 = create(:item, name: "Adult Wipes", partner_key: "adult wipes", kit: kit_2)
        # We will create data both within and outside our date range, and both adult_incontinence and non adult_incontinence.
        # Spec will ensure that only the required data is included.

        # Distributions
        distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
        outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
        (distributions + outside_distributions).each do |dist|
          create_list(:line_item, 5, :distribution, quantity: 200, item: adult_incontinence_item, itemizable: dist)
          create_list(:line_item, 5, :distribution, quantity: 30, item: non_adult_incontinence_item, itemizable: dist)
        end

        kit_distribution_1 = create(:distribution, organization: organization, issued_at: within_time)
        kit_distribution_2 = create(:distribution, organization: organization, issued_at: within_time)

        create(:line_item, :distribution, quantity: 10, item: adult_kit_item_1, itemizable: kit_distribution_1)
        create(:line_item, :distribution, quantity: 10, item: adult_kit_item_2, itemizable: kit_distribution_2)

        # Donations
        donations = create_list(:donation, 2,
                                product_drive: nil,
                                issued_at: within_time,
                                money_raised: 1000,
                                organization: organization)

        donations += create_list(:donation, 2,
                                 product_drive: nil,
                                 issued_at: outside_time,
                                 money_raised: 1000,
                                 organization: organization)

        donations.each do |donation|
          create_list(:line_item, 3, :donation, quantity: 20, item: adult_incontinence_item, itemizable: donation)
          create_list(:line_item, 3, :donation, quantity: 10, item: non_adult_incontinence_item, itemizable: donation)
        end

        # Purchases
        purchases = [
          create(:purchase,
                 issued_at: within_time,
                 organization: organization,
                 purchased_from: 'Google',
                 amount_spent_in_cents: 1000,
                 amount_spent_on_adult_incontinence_cents: 1000),
          create(:purchase,
                 issued_at: within_time,
                 organization: organization,
                 purchased_from: 'Walmart',
                 amount_spent_in_cents: 2000,
                 amount_spent_on_adult_incontinence_cents: 2000),
        ]
        purchases += create_list(:purchase, 2,
                                 issued_at: outside_time,
                                 amount_spent_in_cents: 20_000,
                                 amount_spent_on_adult_incontinence_cents: 20_000,
                                 organization: organization)
        purchases.each do |purchase|
          create_list(:line_item, 3, :purchase, quantity: 30, item: adult_incontinence_item, itemizable: purchase)
          create_list(:line_item, 3, :purchase, quantity: 40, item: non_adult_incontinence_item, itemizable: purchase)
        end
      end

      it 'should report normal values' do
        organization.items.adult_incontinence.first.update!(distribution_quantity: 20)

        expect(report.report[:name]).to eq("Adult Incontinence")
        expect(report.report[:entries]).to match(hash_including({
                                          "% adult incontinence bought" => "60%",
                                          "% adult incontinence supplies donated" => "40%",
                                          "Adults Assisted Per Month" => 10,
                                          "Adult incontinence supplies distributed" => "2,040",
                                          "Adult incontinence supplies per adult per month" => 17.0,
                                          "Money spent purchasing adult incontinence supplies" => "$30.00"
                                        }))
        expect(report.report[:entries]['Adult incontinence supplies'].split(', '))
          .to contain_exactly("Adult Briefs (Large/X-Large)",
                             "Adult Briefs (Medium/Large)",
                             "Adult Briefs (Small/Medium)",
                             "Adult Briefs (XXL)",
                             "Adult Briefs (XXXL)",
                             "Adult Briefs (XS/Small)",
                             "Adult Briefs (XXS)",
                             "Adult Incontinence Pads",
                             "Underpads (Pack)",
                             "Adult Liners",
                             "Wipes (Adult)",
                             "1T Diapers",
                             "2T Diapers")
      end

      it 'should handle null distribution quantity' do
        expect(report.report[:name]).to eq("Adult Incontinence")
        expect(report.report[:entries]).to match(hash_including({
                                          "% adult incontinence bought" => "60%",
                                          "% adult incontinence supplies donated" => "40%",
                                          "Adult incontinence supplies distributed" => "2,040",
                                          "Adults Assisted Per Month" => 5,
                                          "Adult incontinence supplies per adult per month" => 34,
                                          "Money spent purchasing adult incontinence supplies" => "$30.00"
                                      }))
        expect(report.report[:entries]['Adult incontinence supplies'].split(', '))
          .to contain_exactly("Adult Briefs (Large/X-Large)",
                             "Adult Briefs (Medium/Large)",
                             "Adult Briefs (Small/Medium)",
                             "Adult Briefs (XXL)",
                             "Adult Briefs (XXXL)",
                             "Adult Briefs (XS/Small)",
                             "Adult Briefs (XXS)",
                             "Adult Incontinence Pads",
                             "Underpads (Pack)",
                             "Adult Liners",
                             "Wipes (Adult)",
                             "3T Diapers",
                             "4T Diapers")
      end
    end
  end
end
