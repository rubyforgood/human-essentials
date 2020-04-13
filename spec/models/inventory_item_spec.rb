# == Schema Information
#
# Table name: inventory_items
#
#  id                  :integer          not null, primary key
#  quantity            :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  item_id             :integer
#  storage_location_id :integer
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
        expect(create(:inventory_item, quantity: 0)).to be_valid
      end

      it "is less than the max integer" do
        expect(build(:inventory_item, quantity: 2**31)).not_to be_valid
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

  context "Filtering >" do
    describe "->by_partner_key" do
      before(:each) do
        InventoryItem.delete_all
        @item1 = create(:inventory_item)
      end
      it "shows the Base Items by partner_key" do
        expect(InventoryItem.by_partner_key(@item1.item.partner_key).size).to eq(1)
      end
    end
  end
end
