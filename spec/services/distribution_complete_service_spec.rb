RSpec.describe DistributionCompleteService do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item) { create(:item, organization: organization) }
  let(:distribution) do
    dist = create(:distribution, organization: organization, storage_location: storage_location)
    dist.line_items << build(:line_item, quantity: 30, item: item, itemizable: dist)
    dist
  end

  def state
    entry = InventoryAggregate.inventory_for(organization.id).storage_locations[storage_location.id].items[item.id]
    [entry.quantity, entry.reserved_quantity]
  end

  before do
    Flipper.enable(:reserved_inventory)
    TestInventory.create_inventory(organization, {storage_location.id => {item.id => 100}})
  end

  describe "#call" do
    context "when the distribution is scheduled" do
      before { DistributionEvent.publish(distribution) }

      it "is successful" do
        expect(described_class.new(distribution.id).call).to be_success
      end

      it "marks the distribution complete" do
        described_class.new(distribution.id).call
        expect(distribution.reload).to be_complete
      end

      it "releases the reservation without returning it to available" do
        expect { described_class.new(distribution.id).call }.to change { state }.from([70, 30]).to([70, 0])
      end
    end

    context "when the distribution is already complete" do
      before do
        DistributionEvent.publish(distribution)
        described_class.new(distribution.id).call
      end

      it "is not a success" do
        expect(described_class.new(distribution.id).call).not_to be_success
      end

      it "does not release the reservation a second time" do
        expect { described_class.new(distribution.id).call }.not_to change { state }
      end
    end

    context "when the distribution_id matches no Distribution" do
      it "is not a success" do
        expect(described_class.new(Faker::Number.number).call).not_to be_success
      end
    end
  end
end
