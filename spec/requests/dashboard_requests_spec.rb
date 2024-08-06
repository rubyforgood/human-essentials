RSpec.describe "Dashboard", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #show" do
      it "returns http success" do
        get dashboard_path
        expect(response).to be_successful
        expect(response.body).not_to include('switch_to_partner_role')
      end

      context 'with both roles' do
        it 'should include the switch link' do
          partner = FactoryBot.create(:partner)
          user.add_role(Role::PARTNER, partner)
          get dashboard_path
          expect(response.body).to include('switch_to_role')
        end
      end

      context "for another org" do
        it "still displays the user's org" do
          # another org
          get dashboard_path(organization_name: create(:organization).to_param)
          expect(response.body).to include(organization.name)
        end
      end
    end

    context "BroadcastAnnouncement card" do
      it "displays announcements if there are valid ones" do
        BroadcastAnnouncement.create(message: "test announcement", user_id: user.id, organization_id: nil)
        get dashboard_path
        expect(response.body).to include("test announcement")
      end

      it "doesn't display announcements if they are not from super admins" do
        BroadcastAnnouncement.create(message: "test announcement", user_id: user.id, organization_id: organization.id)
        get dashboard_path
        expect(response.body).not_to include("test announcement")
      end
    end
  end

  context "While not signed in" do
    it "redirects for authentication" do
      get dashboard_path
      expect(response).to be_redirect
    end
  end
end
