RSpec.describe Reports::NdbnAnnualsReportService, type: :service do
  xdescribe "#vendors_purchased_from" do
    it "returns where vendors purchased from" do
    end
  end

  xdescribe "#purchased_from" do
    it "returns what stores were purchased from" do
    end
  end

  xdescribe "#money_spent_on_diapers" do
    it "calculates money spent on diapers" do
    end
  end

  xdescribe "#percent_bought" do
    it "calculates percent of diapers bought" do
    end
  end

  xdescribe "#percent_donated" do
    it "calculates percent of diapers donated" do
    end
  end

  xdescribe "#disposabled_diapers_from_drives" do
    it "calculates number of disposable diapers from drivers" do
    end
  end

  describe "#donated_diapers" do
    it "calculates total quantity of diapers donated" do
      create_diaper_donation

      expect(report.donated_diapers).to eq 100
    end
  end

  describe "#diaper_items" do
    it "finds all diaper items" do
      donation = create_diaper_donation

      expect(report.diaper_items).to include(donation.items.first)
    end
  end

  describe "#yearly_donations" do
    it "finds donations from the year" do
      donation = create_diaper_donation

      expect(report.yearly_donations).to include(donation)
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

      expect(report.money_from_drives).to eq 20000
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

      expect(report.money_from_virtual_drives).to eq 10000
    end
  end

  describe "#number_of_diapers_from_virtual_drives" do
    it "finds amount of diapers from virtual diaper drives from year" do
      create_virtual_diaper_drive_donation
      create_diaper_drive_donation

      expect(report.number_of_diapers_from_virtual_drives).to eq 100
    end
  end

  xdescribe "#distributed_diapers" do
    it "calculates number of disposable diapers" do
    end
  end

  xdescribe "#monthly_disposable_diapers" do
    it "calculates number of disposable diapers per month" do
    end
  end

  def create_diaper_donation
    create(:donation, :with_items, organization: organization)
  end

  def create_diaper_drive_donation
    create(:diaper_drive_donation, :with_items, organization: organization, diaper_drive: create(:diaper_drive, virtual: false))
  end

  def create_virtual_diaper_drive_donation
    create(:diaper_drive_donation, :with_items, organization: organization, diaper_drive: create(:diaper_drive, virtual: true))
  end

  def create_diaper_drive(year: Time.zone.now.year, virtual: true)
    create(:diaper_drive, organization: organization, start_date: Time.new(year, 1), end_date: Time.new(year, 2), virtual: virtual)
  end

  def organization
    @organization ||= create(:organization)
  end

  def report
    described_class.new(organization: organization, year: Time.zone.now.year)
  end
end
