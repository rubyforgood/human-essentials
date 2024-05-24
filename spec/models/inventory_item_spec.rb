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
      it { should validate_presence_of(:quantity) }
      it { should validate_numericality_of(:quantity) }
      it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }
      it { should validate_numericality_of(:quantity).is_less_than(2**31) }
      it { should validate_presence_of(:storage_location_id) }
      it { should validate_presence_of(:item_id) }
    end
  end

  it "initializes the quantity to 0 if it was not specified" do
    expect(InventoryItem.new.quantity).to eq(0)
  end

  context "Filtering >" do
    describe "->by_partner_key" do
      it "shows the Inventory Items by partner_key" do
        create(:base_item, partner_key: "UniqueString")
        create(:inventory_item, item: create(:item, partner_key: "UniqueString"))
        expect(InventoryItem.by_partner_key("UniqueString").size).to eq(1)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
