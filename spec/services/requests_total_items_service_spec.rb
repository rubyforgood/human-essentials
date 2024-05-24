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
          create(:request, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 20 } }),
          create(:request, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 10 } })
        ]
      end

      it 'return items with correct quantities calculated' do
        expect(subject.first.last).to eq(30)
      end

      it 'return the names of items correctly' do
        expect(subject.keys).to eq(item_names)
      end
    end

    context 'when item name is nil' do
      let(:item) do
        i = build(:item, name: nil)
        i.save(validate: false)
        i
      end
      let(:requests) do
        [create(:request, request_items: [{ "item_id" => item.id, "quantity" => 20 }])]
      end

      it 'return Unknown Item' do
        expect(subject.first.first).to eq('*Unknown Item*')
      end
    end

    context 'when provided with requests that have no request items' do
      let(:requests) { [create(:request, request_items: {})] }

      it { is_expected.to be_blank }
    end

    context 'when provided requests is nil' do
      let(:requests) { nil }

      it { is_expected.to be_blank }
    end
  end
end
