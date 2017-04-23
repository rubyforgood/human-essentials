# == Schema Information
#
# Table name: partners
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime
#  updated_at :datetime
#

require "rails_helper"

RSpec.describe Partner, type: :model do
  context "Validations >" do
    it "requires a name" do
      expect(build(:partner, name: nil)).not_to be_valid
    end
    it "requires an email" do
      expect(build(:partner, email: nil)).not_to be_valid
    end
  end
end
