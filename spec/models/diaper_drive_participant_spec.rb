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
#  address         :string
#  business_name   :string
#

require 'rails_helper'

RSpec.describe DiaperDriveParticipant, type: :model do
  context "Validations" do
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

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been donated through this diaper drive" do
        ddp = create(:diaper_drive_participant)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:diaper_drive], diaper_drive_participant: ddp)
        expect(ddp.volume).to eq(10)
      end
    end
  end
  describe "import_csv" do
    it "imports storage locations from a csv file" do
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "diaper_drive_participants.csv").read
      DiaperDriveParticipant.import_csv(import_file_path, organization.id)
      expect(DiaperDriveParticipant.count).to eq 3
    end
  end     
end
