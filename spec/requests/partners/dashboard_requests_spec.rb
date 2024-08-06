RSpec.describe "/partners/dashboard", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:partner) { create(:partner, organization: organization) }
  let(:partner_user) { partner.primary_user }

  let(:date) { 1.week.from_now }
  let(:past_date) { 1.week.ago }
  let(:item1) { create(:item, name: "Good item", organization: organization) }
  let(:item2) { create(:item, name: "Crap item", organization: organization) }

  before do
    sign_in(partner_user)
  end

  describe "GET #index" do
    it "displays requests that are pending" do
      request1 = create(:request, :pending, partner: partner, request_items: [])
      create(:item_request, request: request1, quantity: 16, item: item1)

      request2 = create(:request, :pending, partner: partner, request_items: [])
      create(:item_request, request: request2, quantity: 16, item: item2)

      get partners_dashboard_path

      expect(response.body).to include(item1.name)
      expect(response.body).to include(item2.name)
    end

    it "does not display requests in other states" do
      create(:request, :fulfilled, partner: partner, request_items: [{item_id: item1.id, quantity: "16"}])
      create(:request, :started, partner: partner, request_items: [{item_id: item2.id, quantity: "16"}])

      get partners_dashboard_path

      expect(response.body).to_not include(item1.name)
      expect(response.body).to_not include(item2.name)
    end

    it "shows units" do
      Flipper.enable(:enable_packs)
      create(:item_unit, item: item1, name: "Pack")
      create(:item_unit, item: item2, name: "Pack")
      request = create(:request, :pending, partner: partner, request_items: [])
      create(:item_request, request: request, quantity: 1, request_unit: "Pack", item: item1)
      create(:item_request, request: request, quantity: 7, request_unit: "Pack", item: item2)
      get partners_dashboard_path

      expect(response.body).to match(/1\s+Pack\s+—\s+#{item1.name}/m)
      expect(response.body).to match(/7\s+Packs\s+—\s+#{item2.name}/m)
    end

    it "skips units when are not provided" do
      Flipper.enable(:enable_packs)
      create(:item_unit, item: item1, name: "Pack")
      request = create(:request, :pending, partner: partner, request_items: [])
      create(:item_request, request: request, quantity: 7, item: item1)
      get partners_dashboard_path

      expect(response.body).to match(/7\s+#{item1.name}/m)
    end
  end

  it "displays upcoming distributions" do
    create(:distribution, :with_items, partner: partner, organization: partner.organization, issued_at: date)

    get partners_dashboard_path

    expect(response.body).to include("100")
    expect(response.body).to include(date.strftime("%m/%d/%Y"))
  end

  context "with just partner role" do
    it "should not display the switch link" do
      get partners_dashboard_path
      expect(response.body).not_to include("switch_to_role")
    end
  end

  context "with both roles" do
    it "should include the switch link" do
      partner_user.add_role(Role::ORG_USER, organization)
      allow(UsersRole).to receive(:current_role_for).and_return(partner_user.roles.find_by(name: "partner"))
      get partners_dashboard_path
      expect(response.body).to include("switch_to_role")
    end
  end

  context "BroadcastAnnouncement card" do
    it "displays announcements if there are valid ones" do
      BroadcastAnnouncement.create(message: "test announcement", user_id: user.id, organization_id: organization.id)
      get partners_dashboard_path
      expect(response.body).to include("test announcement")
    end

    it "doesn't display announcements if there are not valid ones" do
      BroadcastAnnouncement.create(expiry: 5.days.ago, message: "test announcement", user_id: user.id, organization_id: organization.id)
      get partners_dashboard_path
      expect(response.body).not_to include("test announcement")
    end

    it "doesn't display announcements from super admins" do
      BroadcastAnnouncement.create(message: "test announcement", user_id: user.id, organization_id: nil)
      get partners_dashboard_path
      expect(response.body).not_to include("test announcement")
    end
  end
end
