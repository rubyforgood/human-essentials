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
        local_requests = [
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 20, "request_unit" => "bundle" } }),
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 10, "request_unit" => "bundle" } }),
          create(:request, :with_item_requests, request_items: item_ids.map { |k| { "item_id" => k, "quantity" => 50, "request_unit" => "bundle" } })
        ]
        Request.where(id: local_requests.map(&:id))
      end

      it 'returns items with correct quantities calculated' do
        expect(subject.values.first).to eq(80)
      end

      it 'returns the names of items correctly' do
        expect(subject.keys).to include("item_name_0 - bundles")
      end
    end

    context 'when request_unit is blank' do
      let(:item) { create(:item, :with_unit, name: "Test Item", organization: organization, unit: "piece") }
      let(:requests) do
        request = create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 5, "request_unit" => nil}])
        Request.where(id: request.id)
      end

      it 'handles nil request_unit gracefully' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when request_unit is empty string' do
      let(:item) { create(:item, :with_unit, name: "Test Item", organization: organization, unit: "piece") }
      let(:requests) do
        request = create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 5, "request_unit" => ""}])
        Request.where(id: request.id)
      end

      it 'handles empty request_unit gracefully' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when mixing items with and without request_unit' do
      let(:item1) { create(:item, :with_unit, name: "Item 1", organization: organization, unit: "pack") }
      let(:item2) { create(:item, :with_unit, name: "Item 2", organization: organization, unit: "bundle") }
      let(:requests) do
        local_requests = [
          create(:request, :with_item_requests, request_items: [{"item_id" => item1.id, "quantity" => 10, "request_unit" => "pack"}]),
          create(:request, :with_item_requests, request_items: [{"item_id" => item2.id, "quantity" => 5, "request_unit" => nil}])
        ]
        Request.where(id: local_requests.map(&:id))
      end

      it 'processes mixed request_unit scenarios' do
        expect { subject }.not_to raise_error
        expect(subject.size).to be >= 1
      end
    end

    context 'when quantity is zero' do
      let(:item) { create(:item, :with_unit, name: "Zero Item", organization: organization, unit: "piece") }
      let(:requests) do
        # Create a valid request first, then manually update to bypass validation
        request = create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 1, "request_unit" => "piece"}])
        # Update the quantity to 0 to bypass validation
        request.item_requests.first.update_column(:quantity, 0)
        Request.where(id: request.id)
      end

      it 'includes items with zero quantity' do
        expect(subject["Zero Item - pieces"]).to eq(0)
      end
    end

    context 'when quantity is string' do
      let(:item) { create(:item, :with_unit, name: "String Qty Item", organization: organization, unit: "box") }
      let(:requests) do
        request = create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => "15", "request_unit" => "box"}])
        Request.where(id: request.id)
      end

      it 'converts string quantity to integer' do
        expect(subject["String Qty Item - boxes"]).to eq(15)
      end
    end

    context 'when multiple requests have same item' do
      let(:item) { create(:item, :with_unit, name: "Duplicate Item", organization: organization, unit: "unit") }
      let(:requests) do
        local_requests = [
          create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 10, "request_unit" => "unit"}]),
          create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 20, "request_unit" => "unit"}]),
          create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 30, "request_unit" => "unit"}])
        ]
        Request.where(id: local_requests.map(&:id))
      end

      it 'sums quantities correctly' do
        expect(subject["Duplicate Item - units"]).to eq(60)
      end
    end

    context 'when provided with requests that have no request items' do
      let(:requests) { Request.where(id: [create(:request, :with_item_requests, request_items: {})].map(&:id)) }

      it { is_expected.to be_blank }
    end

    context 'when provided requests is nil' do
      let(:requests) { Request.where(id: nil) }

      it { is_expected.to be_blank }
    end

    context 'when request item belongs to deleted item' do
      let(:item) { create(:item, :with_unit, name: "Diaper", organization: organization, unit: "pack") }
      let!(:requests) do
        request = create(:request, :with_item_requests, request_items: [{"item_id" => item.id, "quantity" => 10, "request_unit" => "pack"}])
        Request.where(id: request.id)
      end

      before do
        item.destroy
      end

      it 'returns item with correct quantity calculated' do
        expect(subject).to eq({"Diaper - packs" => 10})
      end
    end
  end
end
