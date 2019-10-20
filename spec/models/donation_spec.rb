# == Schema Information
#
# Table name: donations
#
#  id                          :integer          not null, primary key
#  source                      :string
#  donation_site_id            :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#  issued_at                   :datetime
#  money_raised                :integer
#  manufacturer_id             :bigint(8)
#  diaper_drive_id             :bigint(8)
#

RSpec.describe Donation, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:donation, organization_id: nil)).not_to be_valid
    end
    it "requires a donation_site if the source is 'Donation Site'" do
      expect(build_stubbed(:donation_site_donation, source: "Donation Site", donation_site: nil)).not_to be_valid
      expect(build(:donation, source: "Misc. Donation", donation_site: nil)).to be_valid
      expect(build_stubbed(:manufacturer_donation, source: "Manufacturer", donation_site: nil)).to be_valid
    end
    it "requires a diaper drive participant if the source is 'Diaper Drive'" do
      expect(build_stubbed(:diaper_drive_donation, source: "Diaper Drive", diaper_drive_participant_id: nil)).not_to be_valid
      expect(build_stubbed(:manufacturer_donation, source: "Manufacturer", diaper_drive_participant_id: nil)).to be_valid
      expect(build(:donation, source: "Misc. Donation", diaper_drive_participant_id: nil)).to be_valid
    end
    it "requires a manufacturer if the source is 'Manufacturer'" do
      expect(build_stubbed(:manufacturer_donation, source: "Manufacturer", manufacturer: nil)).not_to be_valid
      expect(build_stubbed(:diaper_drive_donation, source: "Diaper Drive", manufacturer: nil)).to be_valid
      expect(build(:donation, source: "Misc. Donation", manufacturer: nil)).to be_valid
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
      today = Time.zone.today
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
        create(:donation, created_at: Time.zone.today)
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
        create(:diaper_drive_donation)
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
        create(:line_item, :donation, itemizable: donation)
        expect(donation.items.count).to eq(1)
      end
    end
  end

  context "Methods >" do
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

    describe "money_raised" do
      it "tracks the money raised in a donation" do
        donation = create(:donation, :with_items, money_raised: 100)
        expect(donation.money_raised).to eq(100)
      end
    end

    describe "replace_increase!" do
      let!(:storage_location) { create(:storage_location, organization: @organization) }
      subject { create(:donation, :with_items, organization: @organization, item_quantity: 5, storage_location: storage_location) }

      context "changing the donation" do
        let(:attributes) { { line_items_attributes: { "0": { item_id: subject.line_items.first.item_id, quantity: 2 } } } }

        it "updates the quantity of items" do
          subject
          expect do
            subject.replace_increase!(attributes)
            storage_location.reload
          end.to change { storage_location.size }.by(-3)
        end
      end

      context "when adding an item that has been previously deleted" do
        let!(:inactive_item) { create(:item, active: false) }
        let(:attributes) { { line_items_attributes: { "0": { item_id: inactive_item.to_param, quantity: 10 } } } }

        it "re-creates the item" do
          subject
          expect do
            subject.replace_increase!(attributes)
            storage_location.reload
          end.to change { storage_location.size }.by(5) # We had 5 items of a different kind before, now we have 10
                                                 .and change { Item.active.count }.by(1)
        end
      end

      context "with empty line_items" do
        let(:attributes) { { line_items_attributes: {} } }

        it "removes the inventory item if the item's removal results in a 0 count" do
          subject
          expect do
            subject.replace_increase!(attributes)
            storage_location.reload
          end.to change { storage_location.inventory_items.size }.by(-1)
                                                                 .and change { InventoryItem.count }.by(-1)
        end
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
