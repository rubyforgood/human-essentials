# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint(8)        not null, primary key
#  purchased_from      :string
#  comment             :text
#  organization_id     :integer
#  storage_location_id :integer
#  amount_spent        :integer
#  issued_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

RSpec.describe Purchase, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:purchase, organization_id: nil)).not_to be_valid
    end
    it "requires an inventory (storage location)" do
      expect(build(:purchase, storage_location_id: nil)).not_to be_valid
    end
    it "is invalid when the line items are invalid" do
      d = build(:purchase)
      d.line_items << build(:line_item, quantity: nil)
      expect(d).not_to be_valid
    end
  end

  context "Callbacks >" do
    it "inititalizes the issued_at field to default to created_at if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Date.today
      expect(create(:purchase, created_at: yesterday, issued_at: today).issued_at).to eq(today)
      expect(create(:purchase, created_at: yesterday).issued_at).to eq(yesterday)
    end

    it "automatically combines duplicate line_item records when they're created" do
      purchase = build(:purchase)
      item = create(:item)
      purchase.line_items.build({item_id: item.id, quantity: 5})
      purchase.line_items.build({item_id: item.id, quantity: 10})
      purchase.save
      expect(purchase.line_items.size).to eq(1)
      expect(purchase.line_items.first.quantity).to eq(15)
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all purchases created between two dates" do
        # The models should default to assigning the created_at time to the issued_at
        create(:purchase, created_at: Date.today)
        # but just for fun we'll force one in the past within the range
        create(:purchase, issued_at: Date.yesterday)
        # and one outside the range
        create(:purchase, issued_at: 1.year.ago)

        expect(Purchase.during(1.month.ago..Date.tomorrow).size).to eq(2)
      end
    end
  end

  context "Associations >" do
    describe "items >" do
      it "has_many" do
        purchase = create(:purchase)
        item = create(:item)
        # Using purchase.track because it marshalls the HMT
        purchase.track(item, 1)
        expect(purchase.items.count).to eq(1)
      end
    end

  end

  context "Methods >" do

    describe "track" do
      let!(:purchase) { create(:purchase) }
      let!(:item) { create(:item) }

      it "does not add a new line_item unnecessarily, updating existing line_item instead" do
        item = create :item
        purchase.track(item, 5)
        expect {
          purchase.track(item, 10)
          purchase.reload
        }.not_to change{purchase.line_items.count}

        expect(purchase.line_items.first.quantity).to eq(15)
      end
    end

    describe "contains_item_id?" do
      it "returns true if the item_id already exists" do
        purchase = create(:purchase, :with_items)
        expect(purchase.contains_item_id?(purchase.items.first.id)).to be_truthy
      end
    end

    describe "update_quantity" do
      let!(:purchase) { create(:purchase, :with_items) }
      it "adds an additional quantity to the existing line_item" do
        expect {
          purchase.update_quantity(1, purchase.items.first)
          purchase.reload
        }.to change{purchase.line_items.first.quantity}.by(1)
      end

      it "can receive a negative quantity to subtract inventory" do
        expect {
          purchase.update_quantity(-1, purchase.items.first)
        }.to change{purchase.total_quantity}.by(-1)
      end

      it "works whether you give it an item or an id" do
        expect {
          purchase.update_quantity(1, purchase.items.first.id)
          purchase.reload
        }.to change{purchase.line_items.first.quantity}.by(1)
      end
    end

    describe "remove" do
      let!(:purchase) { create(:purchase, :with_items) }

      it "removes the item from the purchase" do
        item_id = purchase.line_items.last.item_id
        expect {
          purchase.remove(item_id)
        }.to change{purchase.line_items.count}.by(-1)
      end
      
      it "fails gracefully if the item doesn't exist" do
        item_id = create(:item).id
        expect {
          purchase.remove(item_id)
        }.not_to change{purchase.line_items.count}
      end
    end

     describe "remove_inventory" do
      it "removes inventory from the right storage location when purchase deleted" do
        purchase = create(:purchase, :with_items)
        expect {
          purchase.remove_inventory
        }.to change{purchase.storage_location.size}.by(-purchase.total_quantity)
      end
    end
  end
end
