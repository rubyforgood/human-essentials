# Spec for /app/queries/items_in_total_query.rb

RSpec.describe ItemsInTotalQuery do
  let(:organization) { create(:organization) }
  let!(:storage_location) { create(:storage_location, organization: organization) }
  let(:other_item) { create(:item, organization: organization) }
  let!(:other_storage_location) { create(:storage_location, :with_items, item: other_item, item_quantity: 10, organization: organization) }
  let!(:shared_item) { create(:item, organization: organization) }

  subject { ItemsInTotalQuery.new(storage_location: storage_location, organization: organization).call }

  describe "items_in_total_query" do
    before do
      create(:donation, :with_items, item: create(:item, organization: organization), item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:purchase, :with_items, item: create(:item, organization: organization), item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:adjustment, :with_items, item: create(:item, organization: organization), item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:transfer, :with_items, item_quantity: 10, item: other_item, from: other_storage_location, to: storage_location, organization: organization)
    end

    it "returns a sum total of all in-flows" do
      expect(subject).to eq(40)
    end

    it "counts shared items together" do
      create(:donation, :with_items, item: shared_item, item_quantity: 50, storage_location: storage_location, organization: organization)
      create(:purchase, :with_items, item: shared_item, item_quantity: 100, storage_location: storage_location, organization: organization)
      create(:adjustment, :with_items, item: shared_item, item_quantity: 50, storage_location: storage_location, organization: organization)
      create(:donation, :with_items, item: shared_item, item_quantity: 100, storage_location: storage_location, organization: organization)
      create(:purchase, :with_items, item: shared_item, item_quantity: 50, storage_location: storage_location, organization: organization)
      create(:adjustment, :with_items, item: shared_item, item_quantity: 100, storage_location: storage_location, organization: organization)
      expect(subject).to eq(490)
    end

    it "does not count negative adjustments towards in-flow" do
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:adjustment, :with_items, item: shared_item, item_quantity: -10, storage_location: storage_location, organization: organization)
      expect(subject).to eq(50)
    end

    it "does not count transfers going in the negative direction" do
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location, organization: organization)
      create(:transfer, :with_items, item_quantity: 10, item: shared_item, from: storage_location, to: other_storage_location, organization: organization)
      expect(subject).to eq(50)
    end

    it "does not count donations, purchases, adjustments to other storage locations" do
      create(:donation, :with_items, item: create(:item, organization: organization), item_quantity: 100, storage_location: other_storage_location, organization: organization)
      create(:purchase, :with_items, item: create(:item, organization: organization), item_quantity: 10, storage_location: other_storage_location, organization: organization)
      create(:adjustment, :with_items, item: create(:item, organization: organization), item_quantity: 10, storage_location: other_storage_location, organization: organization)
      expect(subject).to eq(40)
    end
  end
end
