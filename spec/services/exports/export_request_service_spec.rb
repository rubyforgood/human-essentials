require "rails_helper"

describe Exports::ExportRequestService do
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

  subject do
    described_class.new([request_3t, request_2t])
  end

  describe ".call" do
    it "includes headers as the first row" do
      expect(subject.call.first).to include("Date", "Requestor", "Status", item_3t.name, item_2t.name)
    end

    it "includes rows for each request" do
      expect(subject.call.second).to include(request_3t.created_at.strftime("%m/%d/%Y").to_s)
      expect(subject.call.second).to include(150)

      expect(subject.call.third).to include(request_2t.created_at.strftime("%m/%d/%Y").to_s)
      expect(subject.call.third).to include(100)
    end
  end
end
