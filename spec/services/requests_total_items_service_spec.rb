RSpec.describe RequestsTotalItemsService, type: :service do
  describe '#calculate' do
    let(:organization) { create(:organization) }
    subject { described_class.new(requests: requests).calculate }

    context 'when the request items is not blank' do
      let(:sample_items) { create_list(:item, 3, :with_unit, organization: organization, unit: "bundle") }
      let(:item_names) { sample_items.pluck(:name) }
      let(:item_ids) { sample_items.pluck(:id) }
      let(:requests) do
        [
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 20 } }),
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 10, "request_unit" => "bundle" } }),
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 50, "request_unit" => "bundle" } })
        ]
      end

      it 'return items with correct quantities calculated' do
        expect(subject.first.last).to eq(80)
      end

      it 'return the names of items correctly' do
        expect(subject.keys).to eq(item_names)
      end

      context 'when custom request units are specified and enabled' do
        before do
          Flipper.enable(:enable_packs)
        end

        it 'returns the names of items correctly' do
          expect(subject.keys).to eq(item_names + item_names.map { |k| "#{k} - bundles" })
        end

        it 'returns items with correct quantities calculated' do
          expect(subject).to eq({
            sample_items.first.name => 20,
            sample_items.first.name + " - bundles" => 60,
            sample_items.second.name => 20,
            sample_items.second.name + " - bundles" => 60,
            sample_items.third.name => 20,
            sample_items.third.name + " - bundles" => 60
          })
        end
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
