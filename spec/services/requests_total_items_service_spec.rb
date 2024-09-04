RSpec.describe RequestsTotalItemsService, type: :service do
  describe '#calculate' do
    let(:organization) { create(:organization) }
    subject { described_class.new(requests: requests).calculate }

    context 'when the request items is not blank' do
      let(:sample_items) { create_list(:item, 3, organization: organization) }
      let(:item_names) { sample_items.pluck(:name) }
      let(:item_ids) { sample_items.pluck(:id) }
      let(:requests) do
        [
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 20 } }),
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 10 } })
        ]
      end

      it 'return items with correct quantities calculated' do
        expect(subject.first.last).to eq(30)
      end

      it 'return the names of items correctly' do
        expect(subject.keys).to eq(item_names)
      end
    end

    context 'when provided with requests that have no request items' do
      let(:requests) { [create(:request, :with_item_requests, request_items: {})] }

      it { is_expected.to be_blank }
    end

    context 'when provided requests is nil' do
      let(:requests) { nil }

      it { is_expected.to be_blank }
    end
  end
end
