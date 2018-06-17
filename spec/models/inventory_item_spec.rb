# == Schema Information
#
# Table name: inventory_items
#
#  id                  :bigint(8)        not null, primary key
#  storage_location_id :integer
#  item_id             :integer
#  quantity            :integer
#  created_at          :datetime
#  updated_at          :datetime
#

RSpec.describe InventoryItem, type: :model do
  context "Validations >" do
    describe "quantity >" do
      it "is required" do
        expect(build(:inventory_item, quantity: nil)).not_to be_valid
      end

      it "is numerical" do
        expect(build(:inventory_item, quantity: "a")).not_to be_valid
      end

      it "is gte 0" do
        expect(build(:inventory_item, quantity: -1)).not_to be_valid
        expect(build(:inventory_item, quantity: 0)).to be_valid
      end
    end
    it "requires an inventory association" do
      expect(build(:inventory_item, storage_location_id: nil)).not_to be_valid
    end
    it "requires an item" do
      expect(build(:inventory_item, item_id: nil)).not_to be_valid
    end
  end

  it "initializes the quantity to 0 if it was not specified" do
    expect(InventoryItem.new.quantity).to eq(0)
  end
end
