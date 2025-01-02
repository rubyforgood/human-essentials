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
        create(:base_item, name: "Adult Briefs (Medium)", partner_key: "adult_briefs_medium", category: "adult incontinence")
        create(:base_item, name: "Adult Briefs (Large)", partner_key: "adult_briefs_large", category: "adult incontinence")
        create(:base_item, name: "Wipes", partner_key: "baby wipes", category: "wipes")

        # adult_incontinence_kit_item_1 = create(:item, name: "Adult Briefs (Medium)", partner_key: "adult_briefs_medium")
        # adult_incontinence_kit_item_2 = create(:item, name: "Adult Briefs (Large)", partner_key: "adult_briefs_large")
        # non_adult_incontinence_kit_item = create(:item, name: "Baby Wipes", partner_key: "baby wipes")

        kit_1 = create(:kit, organization: organization, item: adult_incontinence_kit_item_1 = create(:item, name: "Adult Briefs (Medium)", partner_key: "adult_briefs_medium"))
        kit_2 = create(:kit, organization: organization, item: adult_incontinence_kit_item_2 =create(:item, name: "Adult Briefs (Large)", partner_key: "adult_briefs_large"))
        kit_3 = create(:kit, organization: organization, item: non_adult_incontinence_kit_item = create(:item, name: "Baby Wipes", partner_key: "baby wipes"))

        kit_1.line_items.first.update!(item_id: adult_incontinence_kit_item_1.id, quantity: 5)
        kit_2.line_items.first.update!(item_id: adult_incontinence_kit_item_2.id, quantity: 5)
        kit_3.line_items.first.update!(item_id: non_adult_incontinence_kit_item.id, quantity: 5)
        # kit distributions
        kit_distribution_1 = create(:distribution, organization: organization, issued_at: within_time)
        kit_distribution_2 = create(:distribution, organization: organization, issued_at: within_time)
        # wipes distribution
        kit_distribution_3 = create(:distribution, organization: organization, issued_at: within_time)

        create(:line_item, :distribution, quantity: 10, item: kit_1.item, itemizable: kit_distribution_1)
        create(:line_item, :distribution, quantity: 10, item: kit_2.item, itemizable: kit_distribution_2)
        create(:line_item, :distribution, quantity: 10, item: kit_3.item, itemizable: kit_distribution_3)
        # require 'pry'; binding.pry
        # We will create data both within and outside our date range, and both adult_incontinence and non adult_incontinence.
        # Spec will ensure that only the required data is included.

        # Distributions
        distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
        outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
        (distributions + outside_distributions).each do |dist|
          create_list(:line_item, 5, :distribution, quantity: 200, item: adult_incontinence_item, itemizable: dist)
          create_list(:line_item, 5, :distribution, quantity: 30, item: non_adult_incontinence_item, itemizable: dist)
        end

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

      it "should return the numberof distributed adult incontinence items from kits" do 
        expect(report.distributed_adult_incontinence_items_from_kits).to eq(100)
      end

      it "should return the number of distributed kits only containing adult incontinence items" do
        result = report.total_kits_with_adult_incontinence_items_distributed
        puts result
        expect(result).to eq(2)
      end

      it 'should report normal values' do
        organization.items.adult_incontinence.first.update!(distribution_quantity: 20)
        expect(report.report[:name]).to eq("Adult Incontinence")
        expect(report.report[:entries]).to match(hash_including({
                                          "% adult incontinence bought" => "60%",
                                          "% adult incontinence supplies donated" => "40%",
                                          "Adults Assisted Per Month" => 21,
                                          "Adult incontinence supplies distributed" => "2,120",
                                          "Adult incontinence supplies per adult per month" => 8,
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
                             "Adult Cloth Diapers (Large/XL/XXL)",
                             "Adult Cloth Diapers (Small/Medium)",
                             "Liners (Incontinence)",
                             "Adult Briefs (Large)",
                             "Adult Briefs (Medium)",
                             "1T Diapers", "2T Diapers", "3T Diapers")
      end

      it 'should handle null distribution quantity' do
        expect(report.report[:name]).to eq("Adult Incontinence")
        expect(report.report[:entries]).to match(hash_including({
                                          "% adult incontinence bought" => "60%",
                                          "% adult incontinence supplies donated" => "40%",
                                          "Adult incontinence supplies distributed" => "2,120",
                                          "Adults Assisted Per Month" => 3,
                                          "Adult incontinence supplies per adult per month" => 53,
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
                            "Adult Cloth Diapers (Large/XL/XXL)",
                            "Adult Cloth Diapers (Small/Medium)",
                            "Liners (Incontinence)",
                            "Adult Briefs (Large)",
                            "Adult Briefs (Medium)",
                            "4T Diapers", "5T Diapers", "6T Diapers")
      end
    end
  end
end
