# == Schema Information
#
# Table name: dropoff_locations
#
#  id         :integer          not null, primary key
#  name       :string
#  address    :string
#  created_at :datetime
#  updated_at :datetime
#

require "rails_helper"

RSpec.describe DropoffLocation, type: :model do
	let(:dropoff_location) { FactoryGirl.create :dropoff_location }
	it "has a name" do
		expect(dropoff_location.name).to_not be nil
	end

	it "has an address" do
		expect(dropoff_location.address).to_not be nil
	end
	it "has an array of Donation" do
		expect(dropoff_location.donations).to eq([])

	end
	it "has many donations" do
    assc = described_class.reflect_on_association(:donations)
    expect(assc.macro).to eq :has_many
  end
end

