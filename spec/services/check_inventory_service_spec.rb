RSpec.describe InventoryCheckService, type: :service do
  subject { InventoryCheckService }
  describe "call" do
    let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_minimum_quantity: 5) }
    let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_minimum_quantity: 5) }
    let(:storage_location) do
      storage_location = create(:storage_location)
      create(:inventory_item, storage_location: storage_location, item: item1, quantity: 20)
      create(:inventory_item, storage_location: storage_location, item: item2, quantity: 20)

      storage_location
    end
    let!(:distribution_params) { { organization_id: @organization.id, partner_id: @partner.id, storage_location_id: storage_location.id, line_items_attributes: { "0": { item_id: storage_location.items.first.id, quantity: 5 } } } }

    context "alert" do
      it "should set the alerts" do
        distribution = create(:distribution)
        line_item1 = create(:line_item, item: item1, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)
        line_item2 = create(:line_item, item: item2, itemizable_type: "Distribution", itemizable_id: distribution.id, quantity: 16)

        result = subject.new(distribution).call

        expect(result.alert).to be_instance_of(Alerts::BelowOnHandMinimumQuantity)
      end
    end
  end
end
