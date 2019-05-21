# Spec for /app/queries/items_in_query.rb

RSpec.describe ItemsInQuery do
  let!(:storage_location) { create(:storage_location, organization: @organization) }
  subject { ItemsInQuery.new(storage_location: storage_location, organization: @organization).call }

  describe "items_in" do
    before do
      create_list(:donation, 2, :with_items, item: create(:item), item_quantity: 5, storage_location: storage_location)
      create_list(:purchase, 2, :with_items, item: create(:item), item_quantity: 5, storage_location: storage_location)
      create_list(:adjustment, 2, :with_items, item: create(:item), item_quantity: 5, storage_location: storage_location)
      other_storage_location = create(:storage_location, :with_items, item: create(:item), item_quantity: 10, organization: @organization)
      create_list(:transfer, 2, :with_items, item_quantity: 5, item: other_storage_location.inventory_items.first.item, from: other_storage_location, to: storage_location)
    end

    it "returns a collection with the fields name, item_id, quantity" do
      expect(subject.first).to be_respond_to(:name)
      expect(subject.first).to be_respond_to(:quantity)
      expect(subject.first).to be_respond_to(:item_id)
    end

    it "includes donations, purchases, adjustments, transfers among sources" do
      expect(subject.to_a.size).to eq(4)
    end
  end
end
