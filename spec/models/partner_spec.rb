# == Schema Information
#
# Table name: partners
#
#  id              :integer          not null, primary key
#  name            :string
#  email           :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

RSpec.describe Partner, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:partner, organization_id: nil)).not_to be_valid
    end
    it "requires a unique name" do
      expect(build(:partner, name: nil)).not_to be_valid
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo")).not_to be_valid
    end
    it "requires a unique email that is formatted correctly" do
      expect(build(:partner, email: nil)).not_to be_valid
      create(:partner, email: "foo@bar.com")
      expect(build(:partner, email: "foo@bar.com")).not_to be_valid
      expect(build(:partner, email: "boooooooooo")).not_to be_valid
    end
  end
  describe "import_csv" do
    it "imports storage locations from a csv file" do
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "partners.csv").read
      Partner.import_csv(import_file_path, organization.id)
      expect(Partner.count).to eq 3
    end
  end
end

