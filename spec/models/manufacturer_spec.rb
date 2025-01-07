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

RSpec.describe Manufacturer, type: :model do
  context "Validations" do
    subject { build(:manufacturer) }

    it { should belong_to(:organization) }
    it { should validate_presence_of(:name) }

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

    describe "by_donation_date" do
      before do
        # Prepare manufacturers with donations for tests
        today = Time.zone.today
        from = (today - 1.month).beginning_of_day
        to = today.end_of_day
        dates_in_order = [
          today,
          today - 1.day,
          today - 2.days,
          today - 3.days
        ]

        @mfg1 = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: @mfg1, issued_at: dates_in_order[0])
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: @mfg1, issued_at: dates_in_order[3])
        @mfg2 = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: @mfg2, issued_at: dates_in_order[1])
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: @mfg1, issued_at: dates_in_order[2])
        create(:manufacturer)
        mfg_no_in_range = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: mfg_no_in_range, issued_at: today - 1.year)
        @mfg_by_donation = Manufacturer.all.by_donation_date(10, from..to)
      end

      it "ignores manufacturers with no donations in the date range" do
        expect(@mfg_by_donation.length).to eq(2)
      end

      it "returns manufacturers in order of their most recent donation" do
        expect(@mfg_by_donation).to match_array([@mfg1, @mfg2])
      end
    end
  end

  context "Private Methods" do
    describe "#exists_in_org?" do
      let(:organization) { create(:organization) }

      it "returns true if manufacturer exists in an organization" do
        manufacturer = create(:manufacturer, organization_id: organization.id)
        expect(manufacturer.send(:exists_in_org?)).to eq(true)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
