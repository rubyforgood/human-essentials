require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe "#short_name" do
    it "can only contain valid characters" do
      expect(build(:organization, short_name: 'asdf')).to be_valid
      expect(build(:organization, short_name: 'Not Legal!')).to_not be_valid
    end
  end
end
