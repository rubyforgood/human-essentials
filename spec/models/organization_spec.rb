# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string
#  short_name :string
#  address    :text
#  email      :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

RSpec.describe Organization, type: :model do
  describe "#short_name" do
    it "can only contain valid characters" do
      expect(build(:organization, short_name: 'asdf')).to be_valid
      expect(build(:organization, short_name: 'Not Legal!')).to_not be_valid
    end
  end
end
