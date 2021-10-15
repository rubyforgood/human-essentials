RSpec.describe Reports::AdultIncontinenceReportService, type: :service do
  describe "#adult_incontinence_items" do
    it "returns items relating to adult incontinence" do
      items = report.adult_incontinence_items

      expect(items.length).to eq(4)
    end
  end

  describe "#yearly_line_item_total" do
    it "returns the total items incoming this year" do
      create_purchase
      create_donation

      expect(report.yearly_line_item_total).to eq(20)
    end

    it "doesn't include items from other years" do
      create_purchase(Time.current - 2.years)
      create_purchase(Time.current + 2.years)

      create_donation(Time.current - 2.years)
      create_donation(Time.current + 2.years)

      expect(report.yearly_line_item_total).to eq(0)
    end
  end

  describe "#supplies_distributed" do
    it "adds up all the years distribution" do
      create_distribution

      expect(report.supplies_distributed).to eq(10)
    end

    it "doesn't count other years" do
      create_distribution(Time.current - 2.years)
      create_distribution(Time.current + 2.years)

      expect(report.supplies_distributed).to eq(0)
    end
  end

  describe "#supplies_received" do
    it "returns the percent of supplies donated" do
      create_purchase
      create_purchase
      create_purchase
      create_donation

      expect(report.supplies_received).to eq(25)
    end
  end

  describe "#supplies_purchased" do
    it "returns the percent of supplies donated" do
      create_purchase
      create_donation
      create_donation
      create_donation

      expect(report.supplies_purchased).to eq(25)
    end
  end

  xdescribe "#total_adults_distributed_to" do
    it "needs specs" do
      pending("Implement after method is implemented")
    end
  end

  xdescribe "#provided_per_person" do
    it "needs specs" do
      pending("Implement after method is implemented")
    end
  end

  xdescribe "#money_spent" do
    it "needs specs" do
      pending("Implement after method is implemented")
    end
  end

  def adult_incontinence_item
    Item.find_by(partner_key: described_class::ADULT_INCONTINENCE_TYPES.first, organization: organization)
  end

  def create_purchase(date = Time.current)
    create(:line_item,
           itemizable_type: "Purchase",
           itemizable_id: create(:purchase, issued_at: date).id,
           item: adult_incontinence_item,
           quantity: 10)
  end

  def create_donation(date = Time.current)
    create(:line_item,
           itemizable_type: "Donation",
           itemizable_id: create(:donation, issued_at: date).id,
           item: adult_incontinence_item,
           quantity: 10)
  end

  def create_virtual_diaper_drive_donation
    create(:diaper_drive_donation, :with_items, organization: organization, source: "Diaper Drive", money_raised: 50_000, diaper_drive: create(:diaper_drive, virtual: true))
  end

  def create_distribution(date = Time.current)
    create(:line_item,
           itemizable_type: "Distribution",
           itemizable_id: create(:distribution, issued_at: date).id,
           item: adult_incontinence_item,
           quantity: 10)
  end

  def organization
    @organization ||= create(:organization)
  end

  def report
    described_class.new(organization: organization, year: Time.zone.now.year)
  end
end
