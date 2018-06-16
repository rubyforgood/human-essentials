# == Schema Information
#
# Table name: donations
#
#  id                          :bigint(8)        not null, primary key
#  source                      :string
#  donation_site_id            :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#  issued_at                   :datetime
#

RSpec.describe Donation, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:donation, organization_id: nil)).not_to be_valid
    end
    it "requires a donation_site if the source is 'Donation Site'" do
      expect(build(:donation, source: "Donation Site", donation_site: nil)).not_to be_valid
      expect(build(:donation, source: "Misc. Donation", donation_site: nil)).to be_valid
    end
    it "requires a diaper drive participant if the source is 'Diaper Drive'" do
      expect(build(:donation, source: "Diaper Drive", diaper_drive_participant_id: nil)).not_to be_valid
      expect(build(:donation, source: "Misc. Donation", diaper_drive_participant_id: nil)).to be_valid
    end
    it "requires a source from the list of available sources" do
      expect(build(:donation, source: nil)).not_to be_valid
      expect(build(:donation, source: "Something new")).not_to be_valid
    end
    it "requires an inventory (storage location)" do
      expect(build(:donation, storage_location_id: nil)).not_to be_valid
    end
    it "is invalid when the line items are invalid" do
      d = build(:donation)
      d.line_items << build(:line_item, quantity: nil)
      expect(d).not_to be_valid
    end
  end

  context "Callbacks >" do
    it "inititalizes the issued_at field to default to created_at if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Date.today
      expect(create(:donation, created_at: yesterday, issued_at: today).issued_at).to eq(today)
      expect(create(:donation, created_at: yesterday).issued_at).to eq(yesterday)
    end

    it "automatically combines duplicate line_item records when they're created" do
      donation = build(:donation)
      item = create(:item)
      donation.line_items.build(item_id: item.id, quantity: 5)
      donation.line_items.build(item_id: item.id, quantity: 10)
      donation.save
      expect(donation.line_items.size).to eq(1)
      expect(donation.line_items.first.quantity).to eq(15)
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all donations created between two dates" do
        Donation.destroy_all
        # The models should default to assigning the created_at time to the issued_at
        create(:donation, created_at: Date.today)
        # but just for fun we'll force one in the past within the range
        create(:donation, issued_at: Date.yesterday)
        # and one outside the range
        create(:donation, issued_at: 1.year.ago)
        expect(Donation.during(1.month.ago..Date.tomorrow).size).to eq(2)
      end
    end

    describe "by_source >" do
      before(:each) do
        create(:donation, source: Donation::SOURCES[:misc])
        create(:donation, source: Donation::SOURCES[:diaper_drive])
      end

      it "returns all donations with the provided source" do
        expect(Donation.by_source(Donation::SOURCES[:diaper_drive]).count).to eq(1)
      end

      it "allows a symbol as an argument, referencing the SOURCES hash" do
        expect(Donation.by_source(:diaper_drive).count).to eq(1)
      end
    end
  end

  context "Associations >" do
    describe "items >" do
      it "has_many" do
        donation = create(:donation)
        item = create(:item)
        # Using donation.track because it marshalls the HMT
        donation.track(item, 1)
        expect(donation.items.count).to eq(1)
      end
    end
  end

  context "Methods >" do
    describe "track" do
      let!(:donation) { create(:donation) }
      let!(:item) { create(:item) }

      it "does not add a new line_item unnecessarily, updating existing line_item instead" do
        item = create :item
        donation.track(item, 5)
        expect do
          donation.track(item, 10)
          donation.reload
        end.not_to change { donation.line_items.count }

        expect(donation.line_items.first.quantity).to eq(15)
      end
    end

    describe "contains_item_id?" do
      it "returns true if the item_id already exists" do
        donation = create(:donation, :with_items)
        expect(donation.contains_item_id?(donation.items.last.id)).to be_truthy
      end
    end

    describe "update_quantity" do
      let!(:donation) { create(:donation, :with_items) }
      it "adds an additional quantity to the existing line_item" do
        expect do
          donation.update_quantity(1, donation.items.first)
          donation.reload
        end.to change { donation.line_items.first.quantity }.by(1)
      end

      it "can receive a negative quantity to subtract inventory" do
        expect do
          donation.update_quantity(-1, donation.items.first)
        end.to change { donation.total_quantity }.by(-1)
      end

      it "works whether you give it an item or an id" do
        expect do
          donation.update_quantity(1, donation.items.first.id)
          donation.reload
        end.to change { donation.line_items.first.quantity }.by(1)
      end
    end

    describe "remove" do
      let!(:donation) { create(:donation, :with_items) }

      it "removes the item from the donation" do
        item_id = donation.line_items.last.item_id
        expect do
          donation.remove(item_id)
        end.to change { donation.line_items.count }.by(-1)
      end

      it "works with either an id or an object" do
      end

      it "fails gracefully if the item doesn't exist" do
        item_id = create(:item).id
        expect do
          donation.remove(item_id)
        end.not_to change { donation.line_items.count }
      end
    end

    describe "remove_inventory" do
      it "removes inventory from the right storage location when donation is destroyed" do
        donation = create(:donation, :with_items)
        expect do
          donation.destroy
        end.to change { donation.storage_location.size }.by(-donation.total_quantity)
      end
    end
  end

  describe "SOURCES" do
    it "is a hash that is referenceable by key to avoid 'magic strings'" do
      expect(Donation::SOURCES).to have_key(:diaper_drive)
      expect(Donation::SOURCES).to have_key(:donation_site)
      expect(Donation::SOURCES).to have_key(:misc)
    end
  end
end
