RSpec.describe InventoryCheckService, type: :service do
  let(:organization) { create(:organization) }

  subject { InventoryCheckService }
  describe "call" do
    let(:item1) { create(:item, name: "Item 1", organization: organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
    let(:item2) { create(:item, name: "Item 2", organization: organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }

    context "error" do
      let(:storage_location) do
        storage_location = create(:storage_location, organization: organization)
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            item1.id => 4,
            item2.id => 4
          }
        })

        storage_location
      end

      it "should set the error" do
        distribution = create(:distribution, storage_location_id: storage_location.id)
        create(:line_item, item: item1, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)
        create(:line_item, item: item2, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)

        result = subject.new(distribution.reload).call

        expect(result.error).to eq("The following items have fallen below the minimum on hand quantity: Item 1, Item 2")
        expect(result.alert).to be_nil
      end
    end

    context "alert" do
      let(:storage_location) do
        storage_location = create(:storage_location, organization: organization)
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            item1.id => 9,
            item2.id => 9
          }
        })

        storage_location
      end

      it "should set the alert" do
        distribution = create(:distribution, storage_location_id: storage_location.id)
        create(:line_item, item: item1, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)
        create(:line_item, item: item2, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)

        result = subject.new(distribution.reload).call

        expect(result.alert).to eq("The following items have fallen below the recommended on hand quantity: Item 1, Item 2")
        expect(result.error).to be_nil
      end
    end
  end
end
