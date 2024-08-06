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
end
