RSpec.describe RequestsTotalItemsService, type: :service do
  describe '#calculate' do
    let(:organization) { create(:organization) }
    subject { described_class.new(requests: requests).calculate }

    context 'when the request items is not blank' do
      let(:sample_items) do
        create_list(:item, 3, :with_unit, organization: organization, unit: "bundle") do |item, n|
          item.name = "item_name_#{n}"
          item.save!
        end
      end
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
        expect(subject.keys).to eq([
          "item_name_0",
          "item_name_1",
          "item_name_2"
        ])
      end

      context 'when custom request units are specified and enabled' do
        before do
          Flipper.enable(:enable_packs)
        end

        it 'returns the names of items correctly' do
          expect(subject.keys).to eq([
            "item_name_0",
            "item_name_1",
            "item_name_2",
            "item_name_0 - bundles",
            "item_name_1 - bundles",
            "item_name_2 - bundles"
          ])
        end

        it 'returns items with correct quantities calculated' do
          expect(subject).to eq({
            "item_name_0" => 20,
            "item_name_0 - bundles" => 60,
            "item_name_1" => 20,
            "item_name_1 - bundles" => 60,
            "item_name_2" => 20,
            "item_name_2 - bundles" => 60
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
