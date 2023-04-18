RSpec.describe "Profiles", type: :request do
  let(:partner) { FactoryBot.create(:partner, organization: @organization) }

  let(:default_params) do
    { organization_id: @organization.to_param, id: partner.id, partner_id: partner.id }
  end

  before do
    sign_in(@user)
  end

  describe "GET #edit" do
    it "returns http success" do
      get edit_profile_path(default_params)
      expect(response).to be_successful
    end
  end

  describe "POST #update" do
    context "successful save" do
      let(:partner_params) do
        { name: "Awesome Partner", profile:
                               { executive_director_email: "awesomepartner@example.com", facebook: "facebooksucks" } }
      end

      it "update partner" do
        put profile_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to have_http_status(:redirect)
        expect(partner.reload.name).to eq("Awesome Partner")
        expect(partner.profile.reload.executive_director_email).to eq("awesomepartner@example.com")
        expect(partner.profile.facebook).to eq("facebooksucks")
      end

      it "redirects to #show" do
        put profile_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to redirect_to(partner_path(partner) + "#partner-information")
      end
    end

    context "when updating an existing value to a blank value" do
      let(:partner_params) do
        { name: "Awesome Partner", profile:
                               { executive_director_email: "awesomepartner@example.com", facebook: "", website: "N/A" } }
      end

      it "update partner" do
        put profile_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to have_http_status(:redirect)
        expect(partner.reload.name).to eq("Awesome Partner")
        expect(partner.profile.reload.executive_director_email).to eq("awesomepartner@example.com")
        expect(partner.profile.facebook).to be_nil
      end

      it "should not save N/A value" do
        put profile_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to have_http_status(:redirect)
        expect(partner.profile.website).to be_nil
      end
    end
  end
end
