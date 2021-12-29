RSpec.describe Reports::AdultIncontinenceReportService, type: :service, persisted_data: true do
  # can't use `let` since we are creating a bunch of data in before(:all)
  def year
    2020
  end

  def within_time
    Time.zone.parse("2020-05-31 14:00:00")
  end

  def outside_time
    Time.zone.parse("2019-05-31 14:00:00")
  end

  def organization
    @organization ||= create(:organization)
  end

  before(:all) do
    DatabaseCleaner.start
    seed_base_items_for_tests

    Organization.seed_items(organization)
    adult_incontinence_item = organization.items.adult_incontinence.first
    non_adult_incontinence_item = organization.items.where.not(id: organization.items.adult_incontinence).first

    # We will create data both within and outside our date range, and both adult_incontinence and non adult_incontinence.
    # Spec will ensure that only the required data is included.

    # Distributions
    distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
    outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
    (distributions + outside_distributions).each do |dist|
      create_list(:line_item, 5, :distribution, quantity: 20, item: adult_incontinence_item, itemizable: dist)
      create_list(:line_item, 5, :distribution, quantity: 30, item: non_adult_incontinence_item, itemizable: dist)
    end

    # Donations
    donations = create_list(:donation, 2,
                            diaper_drive: nil,
                            issued_at: within_time,
                            money_raised: 1000,
                            organization: organization)

    donations += create_list(:donation, 2,
                             diaper_drive: nil,
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
             amount_spent_in_cents: 1000),
      create(:purchase,
             issued_at: within_time,
             organization: organization,
             purchased_from: 'Walmart',
             amount_spent_in_cents: 2000),
    ]
    purchases += create_list(:purchase, 2,
                             issued_at: outside_time,
                             amount_spent_in_cents: 20_000,
                             organization: organization)
    purchases.each do |purchase|
      create_list(:line_item, 3, :purchase, quantity: 30, item: adult_incontinence_item, itemizable: purchase)
      create_list(:line_item, 3, :purchase, quantity: 40, item: non_adult_incontinence_item, itemizable: purchase)
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  specify '#report' do
    expect(report.report).to eq({
                                  entries: {
                                    "% adult incontinence bought" => "60%",
                                    "% adult incontinence supplies donated" => "40%",
                                    "Adult incontinence supplies" => "Adult Briefs (Large/X-Large), Adult Briefs (Medium/Large), Adult Briefs (Small/Medium), Adult Briefs (XXL), Adult Briefs (XXXL), Adult Briefs (XS/Small), Adult Briefs (XXS), Adult Incontinence Pads, Underpads (Pack), Adult Liners, Wipes (Adult)",
                                    "Adult incontinence supplies distributed" => "200",
                                    "Adult incontinence supplies per adult per month" => 20,
                                    "Money spent purchasing adult incontinence supplies" => 30.0
                                  },
                                  name: "Adult Incontinence"
                                })
  end
end
