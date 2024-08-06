RSpec.describe Reports::PeriodSupplyReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization, :with_items) }
  
  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe "#report" do
    context "with no values" do 
      it "should report zero values" do
        expect(report.report[:entries]).to match(hash_including({
          "% period supplies bought" => "0%",
          "% period supplies donated" => "0%",
          "Period supplies distributed" => "0",
          "Period supplies per adult per month" => 0,
          "Money spent purchasing period supplies" => "$0.00"
        }))
        expect(report.report[:entries]["Period supplies"].split(", "))
          .to contain_exactly("Tampons", "Pads", "Adult Liners")
      end
    end

    context "with values" do 
      before(:each) do
        Organization.seed_items(organization)

        within_time = Time.zone.parse("2020-05-31 14:00:00")
        outside_time = Time.zone.parse("2019-05-31 14:00:00")

        period_supplies_item = organization.items.period_supplies.first
        non_period_supplies_item = organization.items.where.not(id: organization.items.period_supplies).first

        # We will create data both within and outside our date range, and both period_supplies and non period_supplies.
        # Spec will ensure that only the required data is included.

        # Kits
        period_supplies_kit = create(:kit, :with_item, organization: organization)
        another_period_supply_kit = create(:kit, :with_item, organization: organization)
        donated_period_supply_kit = create(:kit, :with_item, organization: organization)
        purchased_period_supply_kit = create(:kit, :with_item, organization: organization)

        create(:base_item, name: "Adult Pads", partner_key: "adult pads", category: "Menstral Supplies")
        create(:base_item, name: "Adult Tampons", partner_key: "adult tampons", category: "Menstral Supplies")

        period_supplies_kit_item = create(:item, name: "Adult Pads", partner_key: "adult pads")
        another_period_supplies_kit_item = create(:item, name: "Adult Tampons", partner_key: "adult tampons")
        purchased_period_supplies_kit_item = create(:item, name: "Liners", partner_key: "adult tampons")

        period_supplies_kit.line_items.first.update!(item_id: period_supplies_kit_item.id, quantity: 5)
        another_period_supply_kit.line_items.first.update!(item_id: another_period_supplies_kit_item.id, quantity: 5)
        donated_period_supply_kit.line_items.first.update!(item_id: another_period_supplies_kit_item.id, quantity: 5)
        purchased_period_supply_kit.line_items.first.update!(item_id: purchased_period_supplies_kit_item.id, quantity: 5)

        period_supplies_kit_distribution = create(:distribution, organization: organization, issued_at: within_time)
        another_period_supplies_kit_distribution = create(:distribution, organization: organization, issued_at: within_time)

        kit_donation = create(:donation, product_drive: nil, issued_at: within_time, money_raised: 1000, organization: organization)

        kit_purchase = create(:purchase, issued_at: within_time, organization: organization, purchased_from: "TikTok Shop", amount_spent_in_cents: 1000, amount_spent_on_period_supplies_cents: 1000, line_items: [
          create(:line_item, :purchase, item: period_supplies_kit_item, quantity: 5),
          create(:line_item, :purchase, item: purchased_period_supplies_kit_item, quantity: 5)
        ])

        create(:line_item, :distribution, quantity: 10, item: period_supplies_kit.item, itemizable: period_supplies_kit_distribution)
        create(:line_item, :distribution, quantity: 10, item: another_period_supply_kit.item, itemizable: another_period_supplies_kit_distribution)

        create(:line_item, :donation, quantity: 10, item: donated_period_supply_kit.item, itemizable: kit_donation)

        create(:line_item, :purchase, quantity: 30, item: purchased_period_supply_kit.item, itemizable: kit_purchase)

        # create(:purchase, issued_at: within_time, organization: organization, line_items: [
        #   create(:line_item, :purchase, item: period_supplies_kit_item, quantity: 5),
        #   create(:line_item, :purchase, item: purchased_period_supply_kit_item, quantity: 5)
        # ])

        # Distributions
        distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
        outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
        (distributions + outside_distributions).each do |dist|
          create_list(:line_item, 5, :distribution, quantity: 200, item: period_supplies_item, itemizable: dist)
          create_list(:line_item, 5, :distribution, quantity: 30, item: non_period_supplies_item, itemizable: dist)
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
          create_list(:line_item, 3, :donation, quantity: 20, item: period_supplies_item, itemizable: donation)
          create_list(:line_item, 3, :donation, quantity: 10, item: non_period_supplies_item, itemizable: donation)
        end

        # Purchases
        purchases = [
          create(:purchase,
            issued_at: within_time,
            organization: organization,
            purchased_from: "Google",
            amount_spent_in_cents: 1000,
            amount_spent_on_period_supplies_cents: 1000),
          create(:purchase,
            issued_at: within_time,
            organization: organization,
            purchased_from: "Walmart",
            amount_spent_in_cents: 2000,
            amount_spent_on_period_supplies_cents: 2000)
        ]
        purchases += create_list(:purchase, 2,
          issued_at: outside_time,
          amount_spent_in_cents: 20_000,
          amount_spent_on_period_supplies_cents: 20_000,
          organization: organization)
        purchases.each do |purchase|
          create_list(:line_item, 3, :purchase, quantity: 30, item: period_supplies_item, itemizable: purchase)
          create_list(:line_item, 3, :purchase, quantity: 40, item: non_period_supplies_item, itemizable: purchase)
        end
      end

      describe "with values" do
        it "should report normal values" do
          organization.items.period_supplies.first.update!(distribution_quantity: 20)

          expect(report.report[:name]).to eq("Period Supplies")
          expect(report.report[:entries]).to match(hash_including({
            "% period supplies bought" => "66%",
            "% period supplies donated" => "34%",
            "Period supplies distributed" => "2,100",
            "Period supplies per adult per month" => 20,
            "Money spent purchasing period supplies" => "$40.00"
            }))
          expect(report.report[:entries]["Period supplies"].split(", "))
          .to contain_exactly("Tampons", "Pads", "Adult Liners")
        end

        it "returns the correct quantity of period supplies from kits" do
          expect(report.distributed_period_supplies_from_kits).to eq(100)
        end

        it "returns the correct quantity of donated period supplies from kits" do 
          expect(report.donated_supplies_from_kits).to eq(50)
        end

        it "returns the correct quantity of purchased items in kits" do 
          expect(report.purchased_supplies_from_kits).to eq(150)
        end
      end
    end
  end
end
