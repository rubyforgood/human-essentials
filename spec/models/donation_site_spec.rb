# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  active          :boolean          default(TRUE)
#  address         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe DonationSite, type: :model do
  context "Validations >" do
    it { should belong_to(:organization) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
  end

  before(:each) do
    Geocoder.configure(lookup: :test)

    Geocoder::Lookup::Test.add_stub(
      "456 Donation Site Blvd", [
        {"latitude" => 38.8977, "longitude" => -77.0365, "address" => "456 Donation Site Blvd"}
      ]
    )
  end

  describe "import_csv" do
    let(:organization) { create(:organization) }
    let(:valid_csv_path) { Rails.root.join("spec", "fixtures", "files", "valid_donation_sites.csv") }
    let(:invalid_csv_path) { Rails.root.join("spec", "fixtures", "files", "invalid_donation_sites.csv") }
    let(:duplicated_name_csv_path) { Rails.root.join("spec", "fixtures", "files", "duplicated_name_donation_sites.csv") }

    it "captures the error if the name is not unique in the invalid donation sites csv" do
      data = File.read(duplicated_name_csv_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)

      errors, _ = DonationSite.import_csv(csv, organization.id)
      expect(errors).not_to be_empty
      expect(errors.first).to match(/Row/)
      expect(errors.first).to include("Name must be unique within the organization")

      expect(DonationSite.count).to eq 1
    end

    it "imports donation sites from a valid csv file" do
      data = File.read(valid_csv_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)

      errors, _ = DonationSite.import_csv(csv, organization.id)
      expect(errors).to be_empty
      expect(DonationSite.count).to eq 1

      donation_site = DonationSite.first
      expect(donation_site.name).to eq "Donation Site 1"
    end

    it "captures errors when importing donation sites from an invalid csv file" do
      data = File.read(invalid_csv_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)

      errors, _ = DonationSite.import_csv(csv, organization.id)
      expect(errors).not_to be_empty
      expect(errors.first).to match(/Row/)
      expect(errors.first).to include("can't be blank")
      expect(DonationSite.count).to eq 0
    end

    it "imports storage locations from a csv file" do
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "files", "donation_sites.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      DonationSite.import_csv(csv, organization.id)
      expect(DonationSite.count).to eq 1
    end
  end

  describe "geocode" do
    it "adds coordinates to the database" do
      donation_site = build(:donation_site,
                            "address" => "1500 Remount Road, Front Royal, VA 22630")
      donation_site.save
      expect(donation_site.latitude).not_to eq(nil)
      expect(donation_site.longitude).not_to eq(nil)
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end

  describe "active" do
    it "->active shows only donation sites that are still active" do
      DonationSite.delete_all
      donation_site_1 = create(:donation_site, name: "site that will be deactivated", active: true)
      donation_site_2 = create(:donation_site, name: "site that will be active", active: true)
      donation_site_1.deactivate!
      expect(DonationSite.active.to_a).to match_array([donation_site_2])
    end
  end
  describe "deletion" do
    it "can be deleted if there are no donations associated with the donation site" do
      donation_site = build(:donation_site,
                            "address" => "1500 Remount Road, Front Royal, VA 22630")
      donation_site.save
      expect { donation_site.destroy! }.to change { DonationSite.count }.by(-1)
    end

    it "cannot be deleted if there is a donation associated with the donation site" do
      donation_site = build(:donation_site,
                            "address" => "1500 Remount Road, Front Royal, VA 22630")
      donation_site.save
      donation = build(:donation, source: "Donation Site", donation_site: donation_site)
      donation.save
      expect { donation_site.destroy! }
        .to raise_error(/Failed to destroy DonationSite/)
        .and not_change { DonationSite.count }
      expect(donation_site.errors.full_messages).to eq(["Cannot delete record because dependent donations exist"])
    end
  end

  describe "CSV headers" do
    it "returns the correct headers for the CSV export" do
      expected_headers = ["Name", "Address", "Contact Name", "Email", "Phone"]
      expect(DonationSite.csv_export_headers).to eq(expected_headers)
    end
  end

  describe "CSV export attributes" do
    let(:organization) { create(:organization) }
    let!(:active_donation_site) { create(:donation_site, name: "Active Site", address: "1500 Remount Road, Front Royal, VA 22630", active: true, organization: organization) }
    let!(:inactive_donation_site) { create(:donation_site, name: "Inactive Site", address: "1500 Remount Road, Front Royal, VA 22630", active: false, organization: organization) }

    context "when there are active and inactive donation sites" do
      it "includes only active donation sites in the CSV export" do
        csv_data = DonationSite.active.map(&:csv_export_attributes)

        expect(csv_data.count).to eq(1)

        expect(csv_data.first).to eq([
          active_donation_site.name,
          active_donation_site.address,
          active_donation_site.contact_name,
          active_donation_site.email,
          active_donation_site.phone
        ])
      end
    end

    context "when all donation sites are inactive" do
      it "returns no donation sites in the CSV export" do
        csv_data = DonationSite.active.map(&:csv_export_attributes)
        expect(csv_data).to be_empty
      end
      # Deactivate both :active_donation_site and :inactive_donation_site
      before do
        active_donation_site.update(active: false)
      end
    end

    context "when both donation sites are active" do
      it "includes both active donation sites in the CSV export" do
        csv_data = DonationSite.active.map(&:csv_export_attributes)

        expect(csv_data.count).to eq(2)

        expect(csv_data.first).to eq([
          active_donation_site.name,
          active_donation_site.address,
          active_donation_site.contact_name,
          active_donation_site.email,
          active_donation_site.phone
        ])

        expect(csv_data.second).to eq([
          inactive_donation_site.name,
          inactive_donation_site.address,
          inactive_donation_site.contact_name,
          inactive_donation_site.email,
          inactive_donation_site.phone
        ])
      end
      # Activate both :active_donation_site and :inactive_donation_site
      before do
        active_donation_site.update(active: true)
        inactive_donation_site.update(active: true)
      end
    end
  end
end
