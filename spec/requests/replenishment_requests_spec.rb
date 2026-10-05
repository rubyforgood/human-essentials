RSpec.describe "Replenishment", type: :request do
  let(:organization) { create(:organization, enable_replenishment_planner: true) }
  let(:user) { create(:user, organization:) }
  let(:storage_location) { create(:storage_location, organization:, name: "Main Warehouse") }
  let(:item) { create(:item, organization:, name: "Size 3 Diapers") }
  let(:partner_a) { create(:partner, organization:, name: "Small Shelter") }
  let(:partner_b) { create(:partner, organization:, name: "Big Clinic") }

  before do
    6.times do |i|
      d = create(:distribution, organization:, storage_location:, partner: partner_a, issued_at: Time.current.beginning_of_month.months_ago(i + 1))
      d.line_items.create!(item:, quantity: 300)
    end
    TestInventory.create_inventory(organization, {storage_location.id => {item.id => 200}})
  end

  context "when not signed in" do
    it "redirects to sign in" do
      get replenishment_index_path
      expect(response).to be_redirect
    end
  end

  context "when the feature flag is off" do
    before { sign_in(user) }

    it "is not available" do
      Flipper.disable(ReplenishmentController::FEATURE_FLAG)
      get replenishment_index_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the bank has not turned it on" do
    before do
      Flipper.enable(ReplenishmentController::FEATURE_FLAG)
      organization.update!(enable_replenishment_planner: false)
      sign_in(user)
    end

    it "is not available and not in the Reports menu" do
      get replenishment_index_path
      expect(response).to have_http_status(:not_found)

      get dashboard_path
      expect(response.body).not_to include("Replenishment Planner")
    end
  end

  context "when signed in" do
    before do
      Flipper.enable(ReplenishmentController::FEATURE_FLAG)
      sign_in(user)
    end

    it "shows the planner with the item flagged" do
      get replenishment_index_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Replenishment Planner")
      expect(response.body).to include("Size 3 Diapers")
      expect(response.body).to include("Order now")
      expect(response.body).to include("<polyline")
    end

    it "links to the planner from the Reports menu" do
      get dashboard_path
      expect(response.body).to include(replenishment_index_path)
    end

    it "accepts planning assumptions" do
      get replenishment_index_path(lead_time_days: 7, service_level: 0.99, source: "requests")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("7-day lead time")
    end

    it "can be narrowed to one storage location" do
      get replenishment_index_path(storage_location_id: storage_location.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("distributions from Main Warehouse")
    end

    it "ignores a storage location from another organization" do
      other_location = create(:storage_location, organization: create(:organization), name: "Elsewhere")
      get replenishment_index_path(storage_location_id: other_location.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("from Elsewhere")
    end

    it "shows the item page with a shortage allocation and a location breakdown" do
      create(:request, organization:, partner: partner_a, request_items: [{"item_id" => item.id, "quantity" => 50}])
      create(:request, organization:, partner: partner_b, request_items: [{"item_id" => item.id, "quantity" => 400}])

      get replenishment_path(item)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Short by 250")
      expect(response.body).to include("Small Shelter")
      expect(response.body).to include("Max-min fair")
      expect(response.body).to include("By storage location")
      expect(response.body).to include("Main Warehouse")
    end

    it "does not show another organization's items" do
      other_item = create(:item, organization: create(:organization))
      get replenishment_path(other_item)
      expect(response).to have_http_status(:not_found)
    end
  end
end
