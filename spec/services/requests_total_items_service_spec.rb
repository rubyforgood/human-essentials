RSpec.describe RequestsTotalItemsService, type: :service do
  describe '#calculate' do
    subject { described_class.new(requests: requests).calculate }

    context 'when the request items is not blank' do
      let(:requests) do
        items = Item.active.sample(3)
        item_ids = items.pluck(:id)

        [
          create(:request, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 20 } }),
          create(:request, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 10 } })
        ]
      end

      it 'return items with correct quantities calculated' do
        expect(subject.first.last).to eq(30)
      end
    end

    context 'when provided with requests that have no request items' do
      let(:requests) { [create(:request, request_items: {})] }

      it 'return blank when requests itens is blank' do
        expect(subject).to be_blank
      end
    end

    context 'when provided requests is nil' do
      let(:requests) { nil }

      it 'return blank when requests itens is blank' do
        expect(subject).to be_blank
      end
    end
  end
end
