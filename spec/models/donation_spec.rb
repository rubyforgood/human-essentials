# == Schema Information
#
# Table name: donations
#
#  id                  :integer          not null, primary key
#  source              :string
#  completed           :boolean          default(FALSE)
#  dropoff_location_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#

require "rails_helper"

RSpec.describe Donation, type: :model do
	let(:d) { FactoryGirl.create :donation }
	it "has a dropoff location" do
		expect(d.dropoff_location).to_not be nil
	end
	it "has a source" do
		expect(d.source).to_not be nil
	end
	pending "has a receipt number" do
		expect(d.receipt_number).to_not be nil
	end
	it "has a completed flag by default" do
		expect(d.completed).to be false
	end

  describe "validations >" do
	  it "doesn't allow location to blank" do
		  expect(build(:donation, dropoff_location: nil)).not_to be_valid
	  end
	  it "doesn't allow source to be nil" do
		  expect(build(:donation, source: nil)).not_to be_valid
	  end
  end
  it "has many items" do
  	item = create :item
  	d.track(item, 3)
  	expect(d.items.count).to eq(1)
  end
  it "has an item total" do
  	item1 = create :item
  	item2 = create :item
  	d.track(item1, 4)
  	d.track(item2, 5)
  	expect(d.total_items).to eq(9)
  end

  it "belongs to dropoff location" do
    assc = described_class.reflect_on_association(:dropoff_location)
    expect(assc.macro).to eq :belongs_to
  end

	it "tracks from a barcode" do
		donation = create :donation
		barcode_item = create :barcode_item
		expect{donation.track_from_barcode(barcode_item.to_container); donation.reload}.to change{donation.containers.count}.by(1)
	end
	describe "Tracking" do
		it "does not add new container" do
			item = FactoryGirl.create :item
			d.containers.create(quantity: 5, item_id: item.id)
			count = d.containers.count
			d.track(item, 10)
			expect(d.containers.count).to eq(count)
		end
		it "updates donation container's quantity" do
			item = FactoryGirl.create :item
			d.containers.create(quantity: 5, item_id: item.id)
			d.track(item, 10)
			expect(d.containers.find_by(item_id: item.id).quantity).to eq(15)
		end
	end
  it "changes donations to be completed" do
    d.complete
    expect(d.completed).to be true
  end

  describe "scope `#between`" do
    before(:each) { Donation.delete_all }

    it "returns all donations created between two dates" do
      donations = create_list :donation, 5
      start_date = donations.first.created_at - 1.day
      end_date = donations.last.created_at + 1.day
      results = Donation.between(start_date, end_date).to_a
      expect(results).to match donations
    end

    it "does not return donations created outside of two dates" do
      donations = create_list :donation, 5
      results = Donation.between(1.year.ago, 5.months.ago).to_a
      expect(results).to be_empty
    end
  end

  describe "scope `#diaper_drive`" do
    it "returns all donations from a diaper drive" do
      donations = create_list :donation, 3, source: "Diaper Drive"
      results = Donation.diaper_drive
      expect(results.to_a).to match donations
    end

    it "does not return non-diaper drive donations" do
      donations = create_list :donation, 2, source: "Donation"
      results = Donation.diaper_drive
      expect(results.to_a).not_to match donations
    end
  end
end
