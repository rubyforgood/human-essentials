# == Schema Information
#
# Table name: diaper_drive_participants
#
#  id              :integer          not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

require "rails_helper"

RSpec.describe DiaperDriveParticipant, type: :model do
  it_behaves_like "provideable"

  context "Validations" do
    it "is invalid unless it has either a phone number or an email" do
      expect(build(:diaper_drive_participant, phone: nil, email: nil)).not_to be_valid
      expect(build(:diaper_drive_participant, phone: nil)).to be_valid
      expect(build(:diaper_drive_participant, email: nil)).to be_valid
    end

    it "is invalid without an organization" do
      expect(build(:diaper_drive_participant, organization: nil)).not_to be_valid
    end
  end

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been donated through this diaper drive" do
        dd = create(:diaper_drive)
        ddp = create(:diaper_drive_participant)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:diaper_drive], diaper_drive: dd, diaper_drive_participant: ddp)
        expect(ddp.volume).to eq(10)
      end
    end
  end
end
