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
      profiles_params = { name: "Awesome Partner", executive_director_email: "awesomepartner@example.com", facebook: "facebooksucks" }

      it "update partner" do
        put profile_path(default_params.merge(id: partner, partners_partner: profiles_params))
        expect(response).to have_http_status(:redirect)
        partnerbase = partner.profile
        expect(partnerbase.name).to eq("Awesome Partner")
        expect(partnerbase.executive_director_email).to eq("awesomepartner@example.com")
        expect(partnerbase.facebook).to eq("facebooksucks")
      end

      it "redirects to #show" do
        put profile_path(default_params.merge(id: partner, partners_partner: profiles_params))
        expect(response).to redirect_to(partner_path(partner))
      end
    end
  end
end
