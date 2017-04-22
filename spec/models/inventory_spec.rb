# == Schema Information
#
# Table name: inventories
#
#  id         :integer          not null, primary key
#  name       :string
#  address    :string
#  created_at :datetime
#  updated_at :datetime
#

require "rails_helper"

RSpec.describe Inventory, type: :model do
	it "has a name" do
		inventory = build(:inventory, name: nil)
		expect(inventory).not_to be_valid
	end
	it "has an address" do
		inventory = build(:inventory, address: nil)
		expect(inventory).not_to be_valid
	end

	it "can use .size to get total quantity of all items" do
		inventory = create(:inventory)
		create(:holding, inventory_id: inventory.id, quantity: 10)
		create(:holding, inventory_id: inventory.id, quantity: 10)
		expect(inventory.size).to eq(20)
	end

	it "can scope across all inventories by item_id" do
		item = create(:item)
		inventory = create(:inventory_with_items, item_quantity: 10, item: item)
		inventory2 = create(:inventory_with_items, item_quantity: 10, item: item)
		create(:holding, inventory_id: inventory.id, quantity: 10)

		expect(Inventory.item_total(item.id)).to eq(20)
	end

	describe "distribute!" do
	  it "distrbutes items from inventory" do
		  inventory = create :inventory_with_items, item_quantity: 300
                  ticket = build :ticket, :with_items, inventory: inventory, item_quantity: 50
		  inventory.distribute!(ticket)
		  expect(inventory.holdings.first.quantity).to eq 250
	  end

          it "raises error when ticket exceeds inventory" do
		  inventory = create :inventory_with_items, item_quantity: 300
                  ticket = build :ticket, :with_items, inventory: inventory, item_quantity: 350
                  item = ticket.containers.first.item
                  expect {
                    inventory.distribute!(ticket)
                  }.to raise_error { |error|
                    expect(error).to be_a Errors::InsufficientAllotment
                    expect(error.insufficient_items).to include({
                      item_id: item.id,
                      item_name: item.name,
                      quantity_on_hand: 300,
                      quantity_requested: 350
                    })
                  }
	  end
    end

    describe "intake!" do
      let!(:inventory) { create(:inventory) }

      it "adds items to inventory even if none exist" do
      	donation = create(:donation, :with_item, item_quantity: 10)
        expect{
        	inventory.intake!(donation)
            inventory.items.reload
        }.to change{inventory.items.count}.by(1)

      end

      it "adds items to the inventory total if that item already exists in inventory" do
      	inventory = create(:inventory_with_items, item_quantity: 10)
        donation = create(:donation, :with_item, item_quantity: 10, item_id: inventory.holdings.first.item.id)
		inventory.intake!(donation)

		expect(inventory.holdings.count).to eq(1)
		expect(inventory.holdings.where(item_id: donation.containers.first.item.id).first.quantity).to eq(20)

	  end
    end

  describe "reclaim!" do
    it "adds ticket items back to inventory" do
      inventory = create :inventory_with_items, item_quantity: 300
      ticket = create :ticket, :with_items, inventory: inventory, item_quantity: 50
      inventory.reclaim!(ticket)
      expect(inventory.holdings.first.quantity).to eq 350
    end
  end
end
