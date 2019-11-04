# == Schema Information
#
# Table name: manufacturers
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

require "rails_helper"

RSpec.describe Manufacturer, type: :model do
  context "Validations" do
    it "must belong to an organization" do
      expect(build(:manufacturer, organization: nil)).not_to be_valid
      expect(build(:manufacturer, organization: create(:organization))).to be_valid
    end
    it "must have a unique name within organization" do
      manufacturer = create(:manufacturer)
      expect(build(:manufacturer, name: nil)).not_to be_valid
      expect(build(:manufacturer, name: manufacturer.name)).not_to be_valid
    end
  end

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been donated by manufacturer" do
        mfg = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 15, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)
        expect(mfg.volume).to eq(15)
      end

      it "retrieves the amount of product that has been donated by manufacturer from multiple donations" do
        mfg = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 15, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)
        expect(mfg.volume).to eq(25)
      end

      it "ignores the amount of product from other manufacturers" do
        mfg = create(:manufacturer)
        mfg2 = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:manufacturer], manufacturer: mfg2)
        expect(mfg.volume).to eq(5)
      end
    end
  end
end
