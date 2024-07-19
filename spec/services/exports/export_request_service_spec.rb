RSpec.describe Exports::ExportRequestService do
  let(:org) { create(:organization) }

  let(:item_3t) { create :item, name: "3T Diapers" }
  let!(:request_3t) do
    create(:request,
           :started,
           organization: org,
           request_items: [{ item_id: item_3t.id, quantity: 150 }])
  end

  let(:item_2t) { create :item, name: "2T Diapers" }
  let!(:request_2t) do
    create(:request,
           :fulfilled,
           organization: org,
           request_items: [{ item_id: item_2t.id, quantity: 100 }])
  end
  let!(:request_with_deleted_items) do
    create(:request,
           :fulfilled,
           organization: org,
           request_items: [{ item_id: 0, quantity: 200 }, { item_id: -1, quantity: 200 }])
  end

  let!(:unique_items) do
    [
      {item_id: item_3t.id, quantity: 2},
      {item_id: item_2t.id, quantity: 3}
    ]
  end

  let!(:item_quantities) do
    unique_items.each_with_object(Hash.new(0)) do |item, hsh|
      hsh[item[:item_id]] += item[:quantity]
    end
  end

  let!(:request_with_items) do
    create(
      :request,
      :started,
      organization: org,
      request_items: unique_items
    )
  end

  subject do
    described_class.new(Request.all).generate_csv_data
  end

  describe ".generate_csv_data" do
    let(:expected_headers) do
      expected_headers_item_headers = [item_2t, item_3t].map(&:name).sort
      expected_headers_item_headers << Exports::ExportRequestService::DELETED_ITEMS_COLUMN_HEADER
      %w(Date Requestor Status) + expected_headers_item_headers
    end

    it "includes headers as the first row with ordered item names alphabetically with deleted item included at the end" do
      expect(subject.first).to eq(expected_headers)
    end

    it "includes rows for each request with correct columns of item quantity" do
      expect(subject.second).to include(request_3t.created_at.strftime("%m/%d/%Y").to_s)

      item_2t_column_idx = expected_headers.each_with_index.to_h[item_2t.name]
      item_3t_column_idx = expected_headers.each_with_index.to_h[item_3t.name]

      expect(subject.second[item_3t_column_idx]).to eq(150)

      expect(subject.third).to include(request_2t.created_at.strftime("%m/%d/%Y").to_s)
      expect(subject.third[item_2t_column_idx]).to eq(100)

      expect(subject.fourth).to include(request_3t.created_at.strftime("%m/%d/%Y").to_s)
      item_column_idx = expected_headers.each_with_index.to_h[Exports::ExportRequestService::DELETED_ITEMS_COLUMN_HEADER]
      expect(subject.fourth[item_column_idx]).to eq(400)

      expect(subject.fifth[item_2t_column_idx]).to eq(item_quantities[item_2t.id])
      expect(subject.fifth[item_3t_column_idx]).to eq(item_quantities[item_3t.id])
    end
  end
end
