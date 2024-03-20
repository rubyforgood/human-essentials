# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  active          :boolean          default(TRUE)
#  address         :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe DonationSite, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:donation_site, organization_id: nil)).not_to be_valid
    end
    it "is invalid without a name" do
      expect(build(:donation_site, name: nil)).not_to be_valid
    end

    it "is invalid without an address" do
      expect(build(:donation_site, address: nil)).not_to be_valid
    end
  end
  describe "import_csv" do
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
    it "->active shows only items that are still active" do
      DonationSite.delete_all
      donation_site_1 = create(:donation_site, name: "site that will be deactivated", active: true)
      donation_site_2 = create(:donation_site, name: "site that will be active", active: true)
      donation_site_1.deactivate!
      expect(DonationSite.active.to_a).to match_array([donation_site_2])
    end
  end
end
