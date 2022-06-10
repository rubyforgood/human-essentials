# == No Schema Information
#

RSpec.describe RequestItem, type: :model do
  context "Methods >" do
    describe "#from_json" do
      let(:organization) { create :organization }
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
        described_class.from_json(request_item_json.first, request)
      end

      before(:each) do
        create(:inventory_item,
          storage_location: other_location,
          item_id: item1.id,
          quantity: 10)
        create(:inventory_item,
          storage_location: location,
          item_id: item1.id,
          quantity: 20)
        create(:inventory_item,
          storage_location: other_location,
          item_id: item2.id,
          quantity: 30)
        create(:inventory_item,
          storage_location: location,
          item_id: item2.id,
          quantity: 40)
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
