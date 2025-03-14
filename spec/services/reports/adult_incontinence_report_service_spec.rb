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
                                      "Adult incontinence supplies distributed" => "0.0",
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
        create(:base_item, name: "Adult Briefs (small)", partner_key: "adult_briefs_small", category: "adult incontinence")
        create(:base_item, name: "Wipes", partner_key: "baby wipes", category: "wipes")

        adult_incontinence_kit_item_1 = create(:item, name: "Adult Briefs (Medium)", partner_key: "adult_briefs_medium")
        adult_incontinence_kit_item_2 = create(:item, name: "Adult Briefs (Large)", partner_key: "adult_briefs_large")
        adult_incontinence_kit_item_3 = create(:item, name: "Adult Briefs (Small)", partner_key: "adult_briefs_small")
        non_adult_incontinence_kit_item = create(:item, name: "Baby Wipes", partner_key: "baby wipes")

        donation_1 = create(:donation)
        donation_2 = create(:donation)
        donation_3 = create(:donation)
        donation_4 = create(:donation)

        line_item_1 = LineItem.create!(item: adult_incontinence_kit_item_1, itemizable_id: donation_1.id, itemizable_type: "Donation", quantity: 5)
        line_item_2 = LineItem.create!(item: adult_incontinence_kit_item_2, itemizable_id: donation_2.id, itemizable_type: "Donation", quantity: 5)
        line_item_4 = LineItem.create!(item: adult_incontinence_kit_item_3, itemizable_id: donation_4.id, itemizable_type: "Donation", quantity: 5)
        line_item_3 = LineItem.create!(item: non_adult_incontinence_kit_item, itemizable_id: donation_3.id, itemizable_type: "Donation", quantity: 5)

        @kit_1 = create(:kit, line_items: [line_item_1], organization: organization, item: adult_incontinence_kit_item_1)
        @kit_2 = create(:kit, line_items: [line_item_2], organization: organization, item: adult_incontinence_kit_item_2)
        @kit_4 = create(:kit, line_items: [line_item_4], organization: organization, item: adult_incontinence_kit_item_3)
        @kit_3 = create(:kit, line_items: [line_item_3], organization: organization, item: non_adult_incontinence_kit_item)

        # kit distributions
        kit_distribution_1 = create(:distribution, organization: organization, issued_at: within_time)
        kit_distribution_2 = create(:distribution, organization: organization, issued_at: within_time)
        kit_distribution_4 = create(:distribution, organization: organization, issued_at: within_time)
        # wipes distribution
        kit_distribution_3 = create(:distribution, organization: organization, issued_at: within_time)

        create(:line_item, :distribution, quantity: 100, item: @kit_1.line_items.first.item, itemizable: kit_distribution_1)
        create(:line_item, :distribution, quantity: 100, item: @kit_2.line_items.first.item, itemizable: kit_distribution_2)
        create(:line_item, :distribution, quantity: 100, item: @kit_4.line_items.first.item, itemizable: kit_distribution_4)
        create(:line_item, :distribution, quantity: 100, item: @kit_3.line_items.first.item, itemizable: kit_distribution_3)
        # We will create data both within and outside our date range, and both adult_incontinence and non adult_incontinence.
        # Spec will ensure that only the required data is included.

        # Distributions
        distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
        outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
        (distributions + outside_distributions).each do |dist|
          create_list(:line_item, 5, :distribution, quantity: 5000, item: adult_incontinence_item, itemizable: dist)
          create_list(:line_item, 5, :distribution, quantity: 500, item: non_adult_incontinence_item, itemizable: dist)
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
      it "returns an accurate number of adult served per month" do
        within_time = Time.zone.parse("2020-05-31 14:00:00")

        kit_distribution_addition = create(:distribution, organization: organization, issued_at: within_time)
        create(:line_item, :distribution, quantity: 50000, item: @kit_1.line_items.first.item, itemizable: kit_distribution_addition)

        expect(report.adults_served_per_month).to eq(167.41666666666666)
      end

      it "should return the number of loose adult incontinence supplies distributed" do
        expect(report.distributed_adult_incontinence_items_from_kits).to eq(1500.0)
      end
      it "should return the number of distributed adult incontinence items from kits" do
        expect(report.distributed_adult_incontinence_items_from_kits).to eq(1500.0)
      end

      it "should return the number of distributed kits only containing adult incontinence items per month" do
        expect(report.total_distributed_kits_containing_adult_incontinence_items_per_month).to eq(0.25)
      end

      it "should return the kits distributed within a specific year" do
        result = report.distributed_kits_for_year
        expect(result.to_a).to match_array([@kit_1.id, @kit_2.id, @kit_3.id, @kit_4.id])
      end

      it 'should report normal values' do
        organization.items.adult_incontinence.first.update!(distribution_quantity: 20)
        expect(report.report[:name]).to eq("Adult Incontinence")
        expect(report.report[:entries]).to match(hash_including({
                                          "% adult incontinence bought" => "60%",
                                          "% adult incontinence supplies donated" => "40%",
                                          "Adults Assisted Per Month" => 209,
                                          "Adult incontinence supplies distributed" => "51,800.0",
                                          "Adult incontinence supplies per adult per month" => 21,
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
                             "Adult Briefs (Small)",
                             "Adult Briefs (Large)",
                             "Adult Briefs (Medium)")
      end

      it 'should handle null distribution quantity' do
        expect(report.report[:name]).to eq("Adult Incontinence")
        expect(report.report[:entries]).to match(hash_including({
                                          "% adult incontinence bought" => "60%",
                                          "% adult incontinence supplies donated" => "40%",
                                          "Adult incontinence supplies distributed" => "51,800.0",
                                          "Adults Assisted Per Month" => 84,
                                          "Adult incontinence supplies per adult per month" => 51,
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
                            "Adult Briefs (Small)",
                            "Adult Briefs (Large)",
                            "Adult Briefs (Medium)")
      end
    end
  end
end
