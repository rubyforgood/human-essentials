# == Schema Information
#
# Table name: diaper_drive_participants
#
#  id              :bigint(8)        not null, primary key
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  address         :string
#  business_name   :string
#  latitude        :float
#  longitude       :float
#

require "rails_helper"

RSpec.describe DiaperDriveParticipant, type: :model do
  context "Validations" do
    it "is invalid unless it has either a contact name or a business name" do
      expect(build(:diaper_drive_participant, contact_name: nil, business_name: nil)).not_to be_valid
      expect(build(:diaper_drive_participant, contact_name: nil, business_name: "George Company").valid?).to eq(true)
      expect(build(:diaper_drive_participant, contact_name: "George Henry").valid?).to eq(true)
    end

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
        ddp = create(:diaper_drive_participant)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:diaper_drive], diaper_drive_participant: ddp)
        expect(ddp.volume).to eq(10)
      end
    end
  end
  describe "import_csv" do
    it "imports storage locations from a csv file" do
      before_import = DiaperDriveParticipant.count
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "diaper_drive_participants.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      DiaperDriveParticipant.import_csv(csv, organization.id)
      expect(DiaperDriveParticipant.count).to eq before_import + 3
    end
  end

  describe "geocode" do
    it "adds coordinates to the database" do
      ddp = build(:diaper_drive_participant,
                  "address" => "1500 Remount Road, Front Royal, VA 22630")
      ddp.save
      expect(ddp.latitude).not_to eq(nil)
      expect(ddp.longitude).not_to eq(nil)
    end
  end
end
