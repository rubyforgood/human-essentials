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

  context "Scopes" do
    describe "with_volumes" do
      subject { described_class.with_volumes }

      it "retrieves the amount of product that has been donated by manufacturer" do
        mfg = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 15, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)

        expect(subject.first.volume).to eq(15)
      end

      it "retrieves the amount of product that has been donated by manufacturer from multiple donations" do
        mfg = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 15, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)

        expect(subject.first.volume).to eq(25)
      end

      it "ignores the amount of product from other manufacturers" do
        mfg = create(:manufacturer)
        mfg2 = create(:manufacturer)
        create(:donation, :with_items, item_quantity: 5, source: Donation::SOURCES[:manufacturer], manufacturer: mfg)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:manufacturer], manufacturer: mfg2)

        expect(subject.first.volume).to eq(5)
      end
    end
  end

  context "Methods" do
    describe ".donating_in" do
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
        @range = from..to
        @mfg_by_donation = Manufacturer.all.donating_in(@range, limit: 10)
      end

      it "ignores manufacturers with no donations in the date range" do
        expect(@mfg_by_donation.length).to eq(2)
      end

      it "returns them largest first" do
        # `match_array` before, which ignores order -- so the example named for the ordering never
        # asserted one. mfg1 gave 15 items across three donations, mfg2 gave 5.
        expect(@mfg_by_donation.map(&:id)).to eq([@mfg1.id, @mfg2.id])
      end

      it "reports items donated, not a count of donations" do
        # The column was called donation_count and holds sum(line_items.quantity). Under that name
        # the report printed an items figure as though it counted donations.
        expect(@mfg_by_donation.first.items_donated.to_i).to eq(15)
      end

      it "counts every donating manufacturer, not only the ones shown" do
        expect(Manufacturer.all.donating_in_count(@range)).to eq(2)
        # `.to_a` first: `.size` on a grouped relation is a Hash of group counts, not a number.
        expect(Manufacturer.all.donating_in(@range, limit: 1).to_a.size).to eq(1)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
