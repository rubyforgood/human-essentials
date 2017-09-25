# == Schema Information
#
# Table name: dropoff_locations
#
#  id              :integer          not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

RSpec.describe DropoffLocation, type: :model do
	
	context "Validations >" do
		it "must belong to an organization" do
 	      expect(build(:dropoff_location, organization_id: nil)).not_to be_valid
		end
		it "is invalid without a name" do
		  expect(build(:dropoff_location, name: nil)).not_to be_valid
		end

		it "is invalid without an address" do
		  expect(build(:dropoff_location, address: nil)).not_to be_valid
		end
	end
  describe "import_csv" do
    it "imports storage locations from a csv file" do
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "dropoff_locations.csv").read
      DropoffLocation.import_csv(import_file_path, organization.id)
      expect(DropoffLocation.count).to eq 3
    end
  end 	
end

