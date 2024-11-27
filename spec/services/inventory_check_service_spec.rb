RSpec.describe InventoryCheckService, type: :service do
  let(:organization) { create(:organization) }

  subject { InventoryCheckService }
  describe "call" do
    context "when on hand quantity is below the minimum for the organization" do
      let(:first_item) { create(:item, name: "Item 1", organization: organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
      let(:second_item) { create(:item, name: "Item 2", organization: organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
      let(:storage_location) do
        storage_location = create(:storage_location, organization: organization)
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            first_item.id => 4,
            second_item.id => 4
          }
        })

        storage_location
      end
      let(:distribution) { create(:distribution, storage_location_id: storage_location.id) }
      before do
        create(:line_item, item: first_item, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)
        create(:line_item, item: second_item, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)
      end

      it "should set the error" do
        result = subject.new(distribution.reload).call

        expect(result.minimum_alert).to eq("The following items have fallen below the minimum on hand quantity, bank-wide: Item 1, Item 2")
        expect(result.recommended_alert).to be_nil
      end
    end

    context "when on hand quantity is above the minimum for the organization" do
      let(:available_item) { create(:item, name: "Available Item", organization: organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
      let!(:first_storage_location) do
        first_storage_location = create(:storage_location, organization: organization)
        TestInventory.create_inventory(first_storage_location.organization, {
          first_storage_location.id => {
            available_item.id => 9
          }
        })

        first_storage_location
      end
      let!(:second_storage_location) do
        second_storage_location = create(:storage_location, organization: organization)
        TestInventory.create_inventory(second_storage_location.organization, {
          second_storage_location.id => {
            available_item.id => 4
          }
        })

        second_storage_location
      end

      context "when on hand quantity is below the minimum for one storage location" do
        let(:distribution) { create(:distribution, storage_location_id: second_storage_location.id) }
        before do
          create(:line_item, item: available_item, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 2)
        end
        it "should not set the error" do
          result = subject.new(distribution.reload).call

          expect(result.minimum_alert).to be_nil
        end
      end
    end

    context "when on hand quantity is below the recommended amount for the organization" do
      let(:somewhat_stocked_organization) { create(:organization) }
      let(:first_item) { create(:item, name: "Item 1", organization: somewhat_stocked_organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
      let(:second_item) { create(:item, name: "Item 2", organization: somewhat_stocked_organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
      let(:storage_location) do
        storage_location = create(:storage_location, organization: somewhat_stocked_organization)
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            first_item.id => 9,
            second_item.id => 9
          }
        })

        storage_location
      end

      it "should set the alert" do
        distribution = create(:distribution, storage_location_id: storage_location.id)
        create(:line_item, item: first_item, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)
        create(:line_item, item: second_item, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)

        result = subject.new(distribution.reload).call

        expect(result.recommended_alert).to eq("The following items have fallen below the recommended on hand quantity, bank-wide: Item 1, Item 2")
        expect(result.minimum_alert).to be_nil
      end
    end
  end
end
