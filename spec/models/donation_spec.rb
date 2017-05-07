# == Schema Information
#
# Table name: donations
#
#  id                  :integer          not null, primary key
#  source              :string
#  completed           :boolean          default("f")
#  dropoff_location_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#  inventory_id        :integer
#

require "rails_helper"

RSpec.describe Donation, type: :model do
  context "Validations >" do
    it "requires a dropoff_location" do
      expect(build(:donation, dropoff_location: nil)).not_to be_valid
    end
    it "requires a source" do
      expect(build(:donation, source: nil)).not_to be_valid
    end
    it "requires an inventory (storage location)" do
      expect(build(:donation, inventory_id: nil)).not_to be_valid
    end
  end

  it "defaults to incomplete" do
    expect(build(:donation).completed).to be_falsey
  end

  context "Scopes >" do
    describe "completed >" do
      it "shows donations that are flagged complete" do
        create(:donation, completed: false)
        create(:donation, completed: true)
        expect(Donation.completed.count).to eq(1)
      end
    end

    describe "incomplete >" do
      it "shows donations that are flagged incomplete" do
        create(:donation, completed: false)
        create(:donation, completed: true)
        expect(Donation.incomplete.count).to eq(1)
      end
    end
    describe "between >" do
      it "returns all donations created between two dates" do
        create(:donation, created_at: 1.year.ago)
        create(:donation, created_at: Date.yesterday)
        create(:donation, created_at: Date.today)
        expect(Donation.between(1.month.ago, Date.tomorrow).size).to eq(2)
      end
    end

    describe "diaper_drive >" do
      it "returns all donations with the source `Diaper Drive`" do
        create(:donation, source: "Somewhere else")
        create(:donation, source: "Diaper Drive")
        expect(Donation.diaper_drive.count).to eq(1)
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
    describe "total_items" do
      it "has an item total" do
        donation = create(:donation)
        item1 = create :item
        item2 = create :item
        donation.track(item1, 1)
        donation.track(item2, 2)
        expect(donation.total_items).to eq(3)
      end
    end

    describe "track" do
      it "does not add a new container unnecessarily, updating existing container instead" do
        donation = create(:donation)
        item = create :item
        donation.track(item, 5)
        expect {
          donation.track(item, 10)
        }.not_to change{donation.containers.count}

        expect(donation.containers.first.quantity).to eq(15)
      end
    end

    describe "track_from_barcode" do
      it "tracks from a barcode" do
        donation = create :donation
        barcode_item = create :barcode_item
        expect{
          donation.track_from_barcode(barcode_item.to_container); 
          donation.reload
        }.to change{donation.items.count}.by(1)
      end
    end

    describe "complete" do
      it "sets the `completed` field to true" do
        donation = create(:donation)
        expect {
          donation.complete
        }.to change{donation.completed}.from(false).to(true)
      end
    end

    describe "check_existence" do
      it "returns true if the item_id already exists" do
        donation = create(:donation, :with_item)
        expect(donation.check_existence(donation.items.first.id)).to be_truthy
      end
    end

    describe "update_quantity" do
      it "adds an additional quantity to the existing container" do
        donation = create(:donation, :with_item)
        expect { 
          donation.update_quantity(1, donation.items.first)
          donation.reload
        }.to change{donation.containers.first.quantity}.by(1)
      end

      it "works whether you give it an item or an id" do
        pending "TODO: refactor & fix"
        donation = create(:donation, :with_item)
        expect { 
          donation.update_quantity(1, donation.items.first.id)
          donation.reload
        }.to change{donation.containers.first.quantity}.by(1)
      end
    end
  end
end
