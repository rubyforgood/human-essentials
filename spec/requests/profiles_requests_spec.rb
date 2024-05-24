RSpec.describe "Profiles", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:partner) { create(:partner, organization: organization) }

  before do
    sign_in(user)
  end

  describe "GET #edit" do
    it "returns http success" do
      get edit_profile_path(id: partner.id, partner_id: partner.id)
      expect(response).to be_successful
    end

    it "renders edit partner settings partial with enabled request types only" do
      partner.profile.organization.update!(enable_quantity_based_requests: true, enable_child_based_requests: false)
      get edit_profile_path(id: partner.id, partner_id: partner.id)
      expect(response).to render_template(partial: "partners/profiles/edit/_partner_settings")
      expect(response.body).to include("Enable Quantity-based Requests")
      expect(response.body).not_to include("Enable Child-based Requests")
    end
  end

  describe "POST #update" do
    context "successful save" do
      let(:partner_params) do
        { name: "Awesome Partner", profile:
                               { executive_director_email: "awesomepartner@example.com", facebook: "facebooksucks" } }
      end

      it "update partner" do
        put profile_path(id: partner, partner: partner_params)
        expect(response).to have_http_status(:redirect)
        expect(partner.reload.name).to eq("Awesome Partner")
        expect(partner.profile.reload.executive_director_email).to eq("awesomepartner@example.com")
        expect(partner.profile.facebook).to eq("facebooksucks")
      end

      it "updates partner program address" do
        new_partner_program_params = {
          name: partner.name, profile: {
            program_address1: "123 Happy Pl",
            program_city: "Golden",
            program_state: "CO",
            program_zip_code: 80401
          }
        }

        put profile_path(id: partner, partner: new_partner_program_params)

        partner.profile.reload

        expect(response).to have_http_status(:redirect)
        expect(partner.profile.program_address1).to eq("123 Happy Pl")
        expect(partner.profile.program_address2).to be_blank
        expect(partner.profile.program_city).to eq("Golden")
        expect(partner.profile.program_state).to eq("CO")
        expect(partner.profile.program_zip_code).to eq(80401)
      end

      it "redirects to #show" do
        put profile_path(id: partner, partner: partner_params)
        expect(response).to redirect_to(partner_path(partner) + "#partner-information")
      end
    end

    context "when updating an existing value to a blank value" do
      let(:partner_params) do
        { name: "Awesome Partner", profile:
                               { executive_director_email: "awesomepartner@example.com",
                                 no_social_media_presence: true,
                                 facebook: "",
                                 website: "" } }
      end

      it "update partner" do
        put profile_path(id: partner, partner: partner_params)
        expect(response).to have_http_status(:redirect)
        expect(partner.reload.name).to eq("Awesome Partner")
        expect(partner.profile.reload.executive_director_email).to eq("awesomepartner@example.com")
        expect(partner.profile.facebook).to be_blank
      end

      it "should have blank values" do
        put profile_path(id: partner, partner: partner_params)
        expect(response).to have_http_status(:redirect)
        expect(partner.profile.website).to be_blank
      end
    end
  end
end
