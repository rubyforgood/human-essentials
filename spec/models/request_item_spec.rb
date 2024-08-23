# == No Schema Information
#

RSpec.describe RequestItem, type: :model do
  context "Methods >" do
    describe "#from_json" do
      let(:organization) { create(:organization) }
      let(:inventory) { View::Inventory.new(organization.id) }
      let(:location) { create :storage_location, organization: organization }
      let(:other_location) { create :storage_location, organization: organization }
      let(:request) { build :request, organization: organization, request_items: request_item_json }
      let(:item1) { create(:item, organization: organization) }
      let(:item2) { create(:item, organization: organization) }
      let(:request_item_json) do
        [
          {item_id: item1.id, quantity: 15}.stringify_keys,
          {item_id: item2.id, quantity: 18}.stringify_keys
        ]
      end

      subject do
        organization.update!(default_storage_location: location.id)
        described_class.from_json(request_item_json.first, request, inventory)
      end

      before(:each) do
        TestInventory.create_inventory(organization, {
          other_location.id => {
            item1.id => 10,
            item2.id => 30
          },
          location.id => {
            item1.id => 20,
            item2.id => 40
          }
        })
      end

      it 'has the correct name' do
        expect(subject.name).to eq(item1.name)
      end

      it 'has the correct quantity' do
        expect(subject.quantity).to eq(15)
      end

      it 'has the correct amount on hand' do
        expect(subject.on_hand).to eq(30)
      end

      it 'has the correct amount on hand for location' do
        expect(subject.on_hand_for_location).to eq(20)
      end
    end
  end
end
