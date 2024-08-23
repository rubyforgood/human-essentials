RSpec.describe Reports::PeriodSupplyReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization, :with_items) }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe "#report" do
    it "should report zero values" do
      expect(report.report[:entries]).to match(hash_including({
        "% period supplies bought" => "0%",
        "% period supplies donated" => "0%",
        "Period supplies distributed" => "0",
        "Period supplies per adult per month" => 0,
        "Money spent purchasing period supplies" => "$0.00"
      }))
      expect(report.report[:entries]["Period supplies"].split(", "))
        .to contain_exactly("Tampons", "Pads", "Liners (Menstrual)")
    end

    describe "with values" do
      before(:each) do
        Organization.seed_items(organization)

        within_time = Time.zone.parse("2020-05-31 14:00:00")
        outside_time = Time.zone.parse("2019-05-31 14:00:00")

        period_supplies_item = organization.items.period_supplies.first
        non_period_supplies_item = organization.items.where.not(id: organization.items.period_supplies).first

        # We will create data both within and outside our date range, and both period_supplies and non period_supplies.
        # Spec will ensure that only the required data is included.

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

      it "should report normal values" do
        organization.items.period_supplies.first.update!(distribution_quantity: 20)

        expect(report.report[:name]).to eq("Period Supplies")
        expect(report.report[:entries]).to match(hash_including({
          "% period supplies bought" => "60%",
          "% period supplies donated" => "40%",
          "Period supplies distributed" => "2,000",
          "Period supplies per adult per month" => 20,
          "Money spent purchasing period supplies" => "$30.00"
        }))
        expect(report.report[:entries]["Period supplies"].split(", "))
          .to contain_exactly("Tampons", "Pads", "Liners (Menstrual)")
      end
    end
  end
end
