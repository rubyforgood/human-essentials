# == Schema Information
#
# Table name: purchases
#
#  id                    :bigint(8)        not null, primary key
#  purchased_from        :string
#  comment               :text
#  organization_id       :integer
#  storage_location_id   :integer
#  amount_spent_in_cents :integer
#  issued_at             :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  vendor_id             :integer
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
      today = Time.zone.today
      expect(create(:purchase, created_at: yesterday, issued_at: today).issued_at).to eq(today)
      expect(create(:purchase, created_at: yesterday).issued_at).to eq(yesterday)
    end

    it "automatically combines duplicate line_item records when they're created" do
      purchase = build(:purchase)
      item = create(:item)
      purchase.line_items.build(item_id: item.id, quantity: 5)
      purchase.line_items.build(item_id: item.id, quantity: 10)
      purchase.save
      expect(purchase.line_items.size).to eq(1)
      expect(purchase.line_items.first.quantity).to eq(15)
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all purchases created between two dates" do
        Purchase.destroy_all
        # The models should default to assigning the created_at time to the issued_at
        create(:purchase, created_at: Time.zone.today)
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
        create(:line_item, :purchase, itemizable: purchase)
        expect(purchase.items.count).to eq(1)
      end
    end
  end

  context "Methods >" do
    describe "remove" do
      let!(:purchase) { create(:purchase, :with_items) }

      it "removes the item from the purchase" do
        item_id = purchase.line_items.last.item_id
        expect do
          purchase.remove(item_id)
        end.to change { purchase.line_items.count }.by(-1)
      end

      it "fails gracefully if the item doesn't exist" do
        item_id = create(:item).id
        expect do
          purchase.remove(item_id)
        end.not_to change { purchase.line_items.count }
      end
    end

    describe "storage_view" do
      let!(:purchase) { create(:purchase, :with_items) }
      it "returns name of storage location" do
        expect(purchase.storage_view).to eq("Smithsonian Conservation Center")
      end
    end

    describe "replace_increase!" do
      let!(:storage_location) { create(:storage_location, organization: @organization) }
      subject { create(:purchase, :with_items, item_quantity: 5, storage_location: storage_location, organization: @organization) }

      it "updates the quantity of items" do
        attributes = { line_items_attributes: { "0": { item_id: subject.line_items.first.item_id, quantity: 2 } } }
        subject
        expect do
          subject.replace_increase!(attributes)
          storage_location.reload
        end.to change { storage_location.size }.by(-3)
      end

      it "removes the inventory item if the item's removal results in a 0 count" do
        attributes = { line_items_attributes: {} }
        subject
        expect do
          subject.replace_increase!(attributes)
          storage_location.reload
        end.to change { storage_location.inventory_items.size }.by(-1)
                                                               .and change { InventoryItem.count }.by(-1)
      end

      context "when adding an item that has been previously deleted" do
        let!(:inactive_item) { create(:item, active: false, organization: @organization) }
        let(:attributes) { { line_items_attributes: { "0": { item_id: inactive_item.id, quantity: 10 } } } }
        it "re-creates the item" do
          subject
          expect do
            subject.replace_increase!(attributes)
            storage_location.reload
          end.to change { storage_location.size }.by(5)
                                                 .and change { Item.active.count }.by(1)
        end
      end
    end
  end
end
