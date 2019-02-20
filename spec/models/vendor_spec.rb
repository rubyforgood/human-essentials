# == Schema Information
#
# Table name: contractors
#
#  id              :integer          not null, primary key
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
#  type            :string           default("DiaperDriveParticipant")
#

require "rails_helper"

RSpec.describe Vendor, type: :model do
  context "Validations" do
    it "is invalid unless it has either a contact name or a business name" do
      expect(build(:vendor, contact_name: nil, business_name: nil)).not_to be_valid
      expect(build(:vendor, contact_name: nil, business_name: "George Company").valid?).to eq(true)
      expect(build(:vendor, contact_name: "George Henry").valid?).to eq(true)
    end

    it "is invalid unless it has either a phone number or an email" do
      expect(build(:vendor, phone: nil, email: nil)).not_to be_valid
      expect(build(:vendor, phone: nil)).to be_valid
      expect(build(:vendor, email: nil)).to be_valid
    end

    it "is invalid without an organization" do
      expect(build(:vendor, organization: nil)).not_to be_valid
    end
  end

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been bought from this vendor" do
        vendor = create(:vendor)
        create(:purchase, :with_items, item_quantity: 10, amount_spent: 1, vendor: vendor)
        expect(vendor.volume).to eq(10)
      end
    end
  end
  describe "import_csv" do
    it "imports vendors from a csv file" do
      before_import = Vendor.count
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "vendors.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      Vendor.import_csv(csv, organization.id)
      expect(Vendor.count).to eq before_import + 3
    end
  end

  describe "geocode" do
    it "adds coordinates to the database" do
      ddp = build(:vendor,
                  "address" => "1500 Remount Road, Front Royal, VA")
      ddp.save
      expect(ddp.latitude).not_to eq(nil)
      expect(ddp.longitude).not_to eq(nil)
    end
  end
end
