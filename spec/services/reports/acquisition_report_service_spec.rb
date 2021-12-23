RSpec.xdescribe Reports::AcquisitionReportService, type: :service do

  describe "#vendors_purchased_from" do
    it "returns where vendors purchased from" do
    end
  end

  describe "#purchased_from" do
    it "returns what stores were purchased from for the year" do
      create_purchase

      expect(report.purchased_from).to eq ["Google"]
    end
  end

  describe "#money_spent_on_diapers" do
    it "calculates money spent on diapers" do
      create_purchase

      expect(report.money_spent_on_diapers).to eq 10.0
    end
  end

  describe "#percent_bought" do
    it "calculates percent of diapers bought" do
      create_purchase
      create_diaper_drive_donation

      expect(report.percent_bought).to eq 50
    end
  end

  describe "#percent_donated" do
    it "calculates percent of diapers donated" do
      create_purchase
      create_diaper_drive_donation

      expect(report.percent_donated).to eq 50
    end
  end

  describe "#total_annual_incoming_disposable_diapers" do
    it "calculates total diaper count income" do
      create_purchase
      create_diaper_drive_donation

      expect(report.total_annual_incoming_disposable_diapers).to eq 200
    end
  end

  describe "#disposabled_diapers_from_drives" do
    it "calculates number of disposable diapers from drivers" do
      create_diaper_drive_donation

      expect(report.disposable_diapers_from_drives).to eq 100
    end
  end

  describe "#yearly_drive_donations" do
    it "finds donations from the year" do
      donation = create_diaper_drive_donation

      expect(report.yearly_drive_donations).to include(donation)
    end
  end

  describe "#diaper_drives" do
    it "finds diaper drives from the organization" do
      this_year_drive = create_diaper_drive
      last_year_drive = create_diaper_drive(year: Time.zone.now.year - 1)

      expect(report.diaper_drives).to include(this_year_drive)
      expect(report.diaper_drives).to include(last_year_drive)
    end
  end

  describe "#annual_drives" do
    it "finds diaper drives from the year" do
      this_year_drive = create_diaper_drive
      last_year_drive = create_diaper_drive(year: Time.zone.now.year - 1)

      expect(report.annual_drives).to include(this_year_drive)
      expect(report.annual_drives).to_not include(last_year_drive)
    end
  end

  describe "#number_of_diapers_from_drives" do
    it "finds number of diapers from year" do
      create_virtual_diaper_drive_donation
      create_diaper_drive_donation

      expect(report.number_of_diapers_from_drives).to eq 200
    end
  end

  describe "#money_from_drives" do
    it "finds money from diaper drives from year" do
      create_virtual_diaper_drive_donation
      create_diaper_drive_donation

      expect(report.money_from_drives).to eq 1_100
    end
  end

  describe "#virtual_diaper_drives" do
    it "finds number of virtual diaper drives from year" do
      virtual_drive = create_diaper_drive
      non_virtual_drive = create_diaper_drive(virtual: false)

      expect(report.virtual_diaper_drives).to include(virtual_drive)
      expect(report.virtual_diaper_drives).to_not include(non_virtual_drive)
    end
  end

  describe "#money_from_virtual_drives" do
    it "finds amount of money from virtual diaper drives from year" do
      create_virtual_diaper_drive_donation
      create_diaper_drive_donation

      expect(report.money_from_virtual_drives).to eq 500
    end
  end

  describe "#number_of_diapers_from_virtual_drives" do
    it "finds amount of diapers from virtual diaper drives from year" do
      create_virtual_diaper_drive_donation
      create_diaper_drive_donation

      expect(report.number_of_diapers_from_virtual_drives).to eq 100
    end
  end

  describe "#yearly_distributions" do
    it "finds distributions for the year" do
      distribution = create_diaper_distribution

      expect(report.yearly_distributions).to include(distribution)
    end
  end

  describe "#distributed_diapers" do
    it "calculates number of distributed diapers" do
      create_diaper_distribution

      expect(report.distributed_diapers).to eq 100
    end
  end

  describe "#disposable_diaper_items" do
    it "calculates number of disposable diapers" do
      create_diaper_drive_donation

      expect(report.disposable_diaper_items).to include(Item.last)
    end
  end

  describe "#monthly_disposable_diapers" do
    it "calculates number of disposable diapers per month" do
      create_diaper_distribution

      expect(report.monthly_disposable_diapers).to eq 8
    end
  end

  def create_purchase
    create(:purchase, :with_items, organization: organization)
  end

  def create_diaper_drive_donation
    create(:diaper_drive_donation, :with_items, organization: organization, source: "Diaper Drive", money_raised: 60_000, diaper_drive: create(:diaper_drive, virtual: false))
  end

  def create_virtual_diaper_drive_donation
    create(:diaper_drive_donation, :with_items, organization: organization, source: "Diaper Drive", money_raised: 50_000, diaper_drive: create(:diaper_drive, virtual: true))
  end

  def create_diaper_drive(year: Time.zone.now.year, virtual: true)
    create(:diaper_drive, organization: organization, start_date: Time.new(year, 1).getlocal, end_date: Time.new(year, 2).getlocal, virtual: virtual)
  end

  def create_diaper_distribution
    create(:distribution, :with_items, organization: organization)
  end

  def organization
    @organization ||= create(:organization)
  end

  def report
    described_class.new(organization: organization, year: Time.zone.now.year)
  end
end
