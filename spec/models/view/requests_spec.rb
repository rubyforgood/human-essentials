RSpec.describe View::Requests do
  describe "#unfulfilled_requests_count" do
    it "returns the unfulfilled requests count" do
      organization = build(:organization)
      create(:request, :pending, organization:)
      create(:request, :started, organization:)
      create(:request, :fulfilled, organization:)

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.unfulfilled_requests_count).to eq(2)
    end
  end

  describe "#calculate_product_totals" do
    it "returns the calculated product total items" do
      organization = build(:organization)
      build(:request, organization:)
      total_items_service_double = instance_double(RequestsTotalItemsService, calculate: {"Diaper" => 10})
      allow(RequestsTotalItemsService).to receive(:new).with(requests: organization.requests).and_return(total_items_service_double)

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.calculate_product_totals).to eq({"Diaper" => 10})
    end
  end

  describe "#items" do
    it "returns the organization's items id and name, alphabetized" do
      organization = build(:organization)
      build(:request, organization:)
      base_item = build(:base_item)
      item_two = create(:item, base_item:, organization:, name: "B item")
      item_one = create(:item, base_item:, organization:, name: "A item")

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.items.map(&:id)).to eq([item_one.id, item_two.id])
      expect(requests.items.map(&:name)).to eq(["A item", "B item"])
    end
  end

  describe "#partners" do
    it "returns the organization's partners id, name and status, alphabetized" do
      organization = build(:organization)
      build(:request, organization:)
      partner_two = create(:partner, organization:, name: "B partner", status: "approved")
      partner_one = create(:partner, organization:, name: "A partner", status: "invited")

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.partners.map(&:id)).to eq([partner_one.id, partner_two.id])
      expect(requests.partners.map(&:name)).to eq(["A partner", "B partner"])
      expect(requests.partners.map(&:status)).to eq(["invited", "approved"])
    end
  end

  describe "#statuses" do
    it "returns the request statuses" do
      organization = build(:organization)
      build(:request, organization:)
      humanized_statuses = {"Cancelled" => 3, "Fulfilled" => 2, "Pending" => 0, "Started" => 1}

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.statuses).to eq(humanized_statuses)
    end
  end

  describe "#partner_users" do
    it "returns the organization's partner users id, name and email" do
      organization = build(:organization)
      partner_user = create(:partner_user, name: "Jane Smith", email: "janesmith@example.com")
      create(:request, organization:, partner_user:)

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.partner_users.map(&:id)).to eq([partner_user.id])
      expect(requests.partner_users.map(&:name)).to eq(["Jane Smith"])
      expect(requests.partner_users.map(&:email)).to eq(["janesmith@example.com"])
    end
  end

  describe "#request_types" do
    it "returns the request types" do
      organization = build(:organization)
      build(:request, organization:)
      humanized_types = {"Child" => "child", "Individual" => "individual", "Quantity" => "quantity"}

      requests = View::Requests.new(params: {}, organization:, helpers:)

      expect(requests.request_types).to eq(humanized_types)
    end
  end

  describe "selected filter params" do
    it "returns the given filter params" do
      organization = build(:organization)
      build(:request, organization:)
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

      requests = View::Requests.new(params:, organization:, helpers:)

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
