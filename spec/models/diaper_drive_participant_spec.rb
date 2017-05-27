# == Schema Information
#
# Table name: diaper_drive_participants
#
#  id              :integer          not null, primary key
#  name            :string
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'rails_helper'

RSpec.describe DiaperDriveParticipant, type: :model do
  describe "Validations" do
  	it "is invalid without a name" do
      expect(build(:diaper_drive_participant, name: nil)).not_to be_valid
  	end

  	it "is invalid unless it has either a name or an email" do
      expect(build(:diaper_drive_participant, phone: nil, email: nil)).not_to be_valid
      expect(build(:diaper_drive_participant, phone: nil)).to be_valid
      expect(build(:diaper_drive_participant, email: nil)).to be_valid
  	end

    it "is invalid without an organization" do
      expect(build(:diaper_drive_participant, organization: nil)).not_to be_valid
    end
  end
end
