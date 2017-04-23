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
  context "Validations >" do
    it "requires a name" do
      expect(build(:inventory, name: nil)).not_to be_valid
    end
    it "requires an address" do
      expect(build(:inventory, address: nil)).not_to be_valid
    end
  end

  context "Methods >" do
    describe "Inventory.item_total" do
      it "gathers the final total of a single item across all inventories" do
        item = create(:item)
        inv = create(:inventory, :with_items, item_quantity: 10, item: item)
        create(:inventory, :with_items, item_quantity: 10, item: item)
        # This holding will not be included, because it will be for a different item
        create(:holding, inventory_id: inv.id, quantity: 10)
    
        expect(Inventory.item_total(item.id)).to eq(20)
      end
    end

    describe "item_total" do
      it "retrieves the total for a single item" do
        item = create(:item)
        inventory = create(:inventory, :with_items, item_quantity: 10, item: item)
        expect(inventory.item_total(item.id)).to eq(10)
      end
    end

    describe "size" do
      it "returns total quantity of all items in this inventory" do
        inventory = create(:inventory)
        create(:holding, inventory_id: inventory.id, quantity: 10)
        create(:holding, inventory_id: inventory.id, quantity: 10)
        expect(inventory.size).to eq(20)
      end
    end

    describe "intake!" do
      it "adds items to inventory even if none exist" do
        inventory = create(:inventory)
        donation = create(:donation, :with_item, item_quantity: 10)
        expect{
          inventory.intake!(donation)
          inventory.items.reload
        }.to change{inventory.items.count}.by(1)
        expect(inventory.size).to eq(10)
      end

      it "adds items to the inventory total if that item already exists in inventory" do
        inventory = create(:inventory, :with_items, item_quantity: 10)
        donation = create(:donation, :with_item, item_quantity: 10, item_id: inventory.holdings.first.item.id)
        inventory.intake!(donation)

        expect(inventory.holdings.count).to eq(1)
        expect(inventory.holdings.where(item_id: donation.containers.first.item.id).first.quantity).to eq(20)
      end
    end

    describe "distribute!" do
      it "distrbutes items from inventory" do
        inventory = create :inventory, :with_items, item_quantity: 300
        ticket = build :ticket, :with_items, inventory: inventory, item_quantity: 50
        inventory.distribute!(ticket)
        expect(inventory.holdings.first.quantity).to eq 250
      end

      it "raises error when ticket exceeds inventory" do
        inventory = create :inventory, :with_items, item_quantity: 300
        ticket = build :ticket, :with_items, inventory: inventory, item_quantity: 350
        item = ticket.containers.first.item
        expect {
          inventory.distribute!(ticket)
        }.to raise_error do |error|
          expect(error).to be_a Errors::InsufficientAllotment
          expect(error.insufficient_items).to include({
            item_id: item.id,
            item_name: item.name,
            quantity_on_hand: 300,
            quantity_requested: 350
          })
        end
      end
    end

    describe "move_inventory!" do
      pending "removes items from inventory and adds them to another inventory"

      pending "raises error when ticket exceeds inventory"
    end

    describe "reclaim!" do
      it "adds ticket items back to inventory" do
        inventory = create :inventory, :with_items, item_quantity: 300
        ticket = create :ticket, :with_items, inventory: inventory, item_quantity: 50
        inventory.reclaim!(ticket)
        expect(inventory.holdings.first.quantity).to eq 350
      end
    end

    describe "total_inventory" do
      it "totals up the sum of all units held in the inventory, agnostic of item type" do
        inventory = create(:inventory, :with_items, item_quantity: 10)
        expect(inventory.total_inventory).to eq(10)
      end
    end

  end
end
