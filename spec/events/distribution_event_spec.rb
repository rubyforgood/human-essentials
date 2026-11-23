RSpec.describe DistributionEvent do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item) { create(:item, organization: organization) }
  let(:distribution) do
    dist = create(:distribution, organization: organization, storage_location: storage_location)
    dist.line_items << build(:line_item, quantity: 30, item: item, itemizable: dist)
    dist
  end

  before { TestInventory.create_inventory(organization, {storage_location.id => {item.id => 100}}) }

  describe ".publish" do
    subject { described_class.publish(distribution).data.reserves_inventory }

    context "when the feature is enabled for the organization" do
      before { Flipper.enable(:reserved_inventory) }

      it { is_expected.to be true }

      context "when the distribution is already complete" do
        before do
          distribution.complete!          
        end

        it { is_expected.to be false }
      end
      
    end

    context "when the feature is not enabled for the organization" do
      before do
        expect(Flipper.enabled?(:reserved_inventory)).to eq false
      end

      it { is_expected.to be false }
    end
  end
end
