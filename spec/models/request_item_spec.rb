# == No Schema Information
#

RSpec.describe RequestItem, type: :model do
  context "Methods >" do
    describe "#from_json" do
      let(:organization) { build :organization }
      let(:request) { build :request, organization: organization }
      let(:request_item_json) { request.request_items.first }
      let(:item) { Item.find(request_item_json['item_id']) }

      subject { described_class.from_json(request_item_json, organization) }

      it 'has the correct name' do
        expect(subject.name).to eq(item.name)
      end

      it 'has the correct quantity' do
        expect(subject.quantity).to eq(request_item_json['quantity'])
      end

      it 'has the correct amount on hand' do
        # NOTE: this is an unpersisted organization that shouldn't have anything on hand
        expect(subject.on_hand).to eq(0)
      end
    end
  end
end
