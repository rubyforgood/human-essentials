# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  active          :boolean          default(TRUE)
#  city            :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  phone           :string
#  state           :string
#  street          :string
#  zipcode         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe DonationSite, type: :model do
  context "Validations >" do
    it { should belong_to(:organization) }
    it { should validate_presence_of(:name) }
    # `street`, not `address`: the address is composed from four columns now, so validating the
    # composition would accept a record with a city and nothing else. Whatever the parser cannot
    # place lands in `street`, which makes it the part that is always present.
    it { should validate_presence_of(:street) }
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

      errors = DonationSite.import_csv(csv, organization.id)
      expect(errors).not_to be_empty
      expect(errors.first).to match(/Row/)
      expect(errors.first).to include("Name must be unique within the organization")

      expect(DonationSite.count).to eq 1
    end

    it "imports donation sites from a valid csv file" do
      data = File.read(valid_csv_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)

      errors = DonationSite.import_csv(csv, organization.id)
      expect(errors).to be_empty
      expect(DonationSite.count).to eq 1

      donation_site = DonationSite.first
      expect(donation_site.name).to eq "Donation Site 1"
    end

    it "still takes a single address column, and splits it" do
      # **This is the whole reason the import template did not change** when the address became four
      # columns: 200+ banks have downloaded these templates and keep local copies, and a saved file
      # with one `address` column has to keep working. `import_csv` does `new(row.to_hash)`, so the
      # split happens in `StructuredAddress#address=`. See design.md, "Address fields".
      csv = CSV.parse(<<~CSV, headers: true)
        name,address,contact_name,email,phone
        Site,"1500 Remount Road, Front Royal, VA 22630",Joanna,jo@example.com,123-456-7890
      CSV

      expect(DonationSite.import_csv(csv, organization.id)).to be_empty

      site = DonationSite.last
      expect(site.street).to eq "1500 Remount Road"
      expect(site.city).to eq "Front Royal"
      expect(site.state).to eq "VA"
      expect(site.zipcode).to eq "22630"
      # And it reads back exactly as it went in, which is what the geocoder and the PDFs see.
      expect(site.address).to eq "1500 Remount Road, Front Royal, VA 22630"
    end

    it "captures errors when importing donation sites from an invalid csv file" do
      data = File.read(invalid_csv_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)

      errors = DonationSite.import_csv(csv, organization.id)
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

    # The query the CSV export actually runs. `DonationSitesController#index` builds
    # `current_organization.donation_sites.alphabetized.active` and hands that to `generate_csv`.
    #
    # These examples used a bare `DonationSite.active`, which differed from the app in two ways,
    # and both made them flaky rather than stably wrong:
    #
    #   * **Unscoped by organization**, so any donation site belonging to another one changes the
    #     count. Nothing leaks today, but the assertion was one stray record from failing and said
    #     nothing about the export, which is always scoped.
    #   * **Unordered**, while the assertions index `.first` and `.second`. Postgres promises no
    #     order without `ORDER BY`; a sequential scan happens to return heap order, and the
    #     `before` blocks below `update` a row, which writes a new tuple at the end of the heap.
    #     So the expected order held by accident of MVCC until, on one run in fifteen, it did not.
    #
    # Caught by a full-suite run on 2026-09-04, not by this file, which passes on its own every
    # time.
    def exported_donation_sites
      organization.donation_sites.alphabetized.active.map(&:csv_export_attributes)
    end

    context "when there are active and inactive donation sites" do
      it "includes only active donation sites in the CSV export" do
        csv_data = exported_donation_sites

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

    # The two guards below are the point of the change: each one fails against the bare
    # `DonationSite.active` these examples used to call, and passes against the query the app
    # actually runs. Without them the fix is invisible -- every example here passed before it too.
    context "when another organization has donation sites" do
      it "excludes them, because the export is always organization-scoped" do
        create(:donation_site, name: "Someone Else's Site", active: true,
          organization: create(:organization))

        expect(exported_donation_sites.count).to eq(1)
        expect(exported_donation_sites.first.first).to eq("Active Site")
      end
    end

    context "when a site sorts before one created earlier" do
      it "returns them by name rather than by insertion order" do
        # Created last, sorts first. Insertion order would put it at the end, which is what an
        # unordered query returns on a sequential scan.
        create(:donation_site, name: "AAA Site", active: true, organization: organization)

        expect(exported_donation_sites.map(&:first)).to eq(["AAA Site", "Active Site"])
      end
    end

    context "when all donation sites are inactive" do
      it "returns no donation sites in the CSV export" do
        csv_data = exported_donation_sites
        expect(csv_data).to be_empty
      end
      # Only the active one needs deactivating; the other is created inactive.
      before do
        active_donation_site.update(active: false)
      end
    end

    context "when both donation sites are active" do
      it "includes both active donation sites in the CSV export" do
        csv_data = exported_donation_sites

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
