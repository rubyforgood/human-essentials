# == Schema Information
#
# Table name: donation_sites
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
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
      import_file_path = Rails.root.join("spec", "fixtures", "donation_sites.csv").read
      DonationSite.import_csv(import_file_path, organization.id)
      expect(DonationSite.count).to eq 3
    end
  end
end

