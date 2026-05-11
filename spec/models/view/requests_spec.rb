RSpec.describe View::Requests do
  describe "#unfulfilled_requests_count" do
    it "returns the unfulfilled requests count" do
      organization = build(:organization)
      create(:request, :pending, organization:)
      create(:request, :started, organization:)
      create(:request, :fulfilled, organization:)

      requests = View::Requests.from_params(params: {}, organization:, helpers:)

      expect(requests.unfulfilled_requests_count).to eq(2)
    end
  end

  describe "#calculate_product_totals" do
    it "returns the calculated product total items" do
      organization = build(:organization)
      build(:request, :pending, organization:)
      total_items_service_double =  instance_double(RequestsTotalItemsService, calculate: {"Diaper" => 10})
      allow(RequestsTotalItemsService).to receive(:new).with(requests: organization.requests).and_return(total_items_service_double)

      requests = View::Requests.from_params(params: {}, organization:, helpers:)

      expect(requests.calculate_product_totals).to eq({"Diaper" => 10})
    end
  end

  describe "selected filter params" do
    it "returns the given filter params" do
      organization = build(:organization)
      build(:request, :pending, organization:)
      params = ActionController::Parameters.new(
      {
        filters: {
          by_request_type: "quantity",
          by_request_item_id: "1",
          by_partner: "A Local Partner",
          by_status: "pending"
        }
      }
    ).permit!

      requests = View::Requests.from_params(params:, organization:, helpers:)

      expect(requests.selected_request_type).to eq("quantity")
      expect(requests.selected_request_item).to eq("1")
      expect(requests.selected_partner).to eq("A Local Partner")
      expect(requests.selected_status).to eq("pending")
    end
  end

  def helpers
    Module.new do
      def self.selected_range
        (1.month.ago..2.days.from_now)
      end
    end
  end
end
