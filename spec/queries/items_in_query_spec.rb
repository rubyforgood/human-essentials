# Spec for /app/queries/items_in_query.rb

RSpec.describe ItemsInQuery do
  let(:organization) { create(:organization) }
  let!(:storage_location) { create(:storage_location, organization: organization) }
  let(:other_item) { create(:item, organization: organization) }
  let!(:other_storage_location) { create(:storage_location, :with_items, item: other_item, item_quantity: 10, organization: organization) }

  subject { ItemsInQuery.new(storage_location: storage_location, organization: organization).call }

  describe "items_in" do
    before do
      create_list(:donation, 2, :with_items, item: create(:item, organization: organization), item_quantity: 5, storage_location: storage_location, organization: organization)
      create_list(:purchase, 2, :with_items, item: create(:item, organization: organization), item_quantity: 5, storage_location: storage_location, organization: organization)
      create_list(:adjustment, 2, :with_items, item: create(:item, organization: organization), item_quantity: 5, storage_location: storage_location, organization: organization)
      create_list(:transfer, 2, :with_items, item_quantity: 5, item: other_item, from: other_storage_location, to: storage_location, organization: organization)
    end

    it "returns a collection with the fields name, item_id, quantity" do
      expect(subject.first).to be_respond_to(:name)
      expect(subject.first).to be_respond_to(:quantity)
      expect(subject.first).to be_respond_to(:item_id)
    end

    it "includes donations, purchases, adjustments, transfers among sources" do
      expect(subject.to_a.size).to eq(4)
    end

    it "does not count negative adjustments towards in-flow" do
      shared_item = create(:item, organization: organization)
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:adjustment, :with_items, item: shared_item, item_quantity: -10, storage_location: storage_location, organization: organization)
      expect(subject.to_a.size).to eq(5)
    end

    it "does not count transfers going in the negative direction" do
      shared_item = create(:item, organization: organization)
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:transfer, :with_items, item_quantity: 10, item: shared_item, from: storage_location, to: other_storage_location, organization: organization)
      expect(subject.to_a.size).to eq(5)
    end
  end
end
