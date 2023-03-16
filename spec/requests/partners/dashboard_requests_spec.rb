require "rails_helper"

RSpec.describe "/partners/dashboard", type: :request do
  let(:partner) { create(:partner) }
  let(:partner_user) { partner.primary_user }
  let(:date) { 1.week.from_now }
  let(:past_date) { 1.week.ago }
  let(:item1) { create(:item, name: "Good item") }
  let(:item2) { create(:item, name: "Crap item") }

  before do
    sign_in(partner_user)
  end

  describe "GET #index" do
    it "displays requests that are pending" do
      FactoryBot.create(:request, :pending, partner: partner,
        request_items: [{item_id: item1.id, quantity: "16"}])
      FactoryBot.create(:request, :pending, partner: partner,
        request_items: [{item_id: item2.id, quantity: "16"}])
      get partners_dashboard_path
      expect(response.body).to include(item1.name)
      expect(response.body).to include(item2.name)
    end

    it "does not display requests in other states" do
      FactoryBot.create(:request, :fulfilled, partner: partner,
        request_items: [{item_id: item1.id, quantity: "16"}])
      FactoryBot.create(:request, :started, partner: partner,
        request_items: [{item_id: item2.id, quantity: "16"}])
      get partners_dashboard_path
      expect(response.body).to_not include(item1.name)
      expect(response.body).to_not include(item2.name)
    end
  end

  it "displays upcoming distributions" do
    FactoryBot.create(:distribution, :with_items, partner: partner, organization: partner.organization, issued_at: date)
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
      partner_user.add_role(Role::ORG_USER, @organization)
      get partners_dashboard_path
      expect(response.body).to include("switch_to_role")
    end
  end

  context "BroadcastAnnouncement card" do
    it "displays announcements if there are valid ones" do
      BroadcastAnnouncement.create(message: "test announcement", user_id: 1, organization_id: 1)
      get partners_dashboard_path
      expect(response.body).to include("test announcement")
    end

    it "doesn't display announcements if there are not valid ones" do
      BroadcastAnnouncement.create(expiry: 5.days.ago, message: "test announcement", user_id: 1, organization_id: 1)
      get partners_dashboard_path
      expect(response.body).not_to include("test announcement")
    end
  end
end
