RSpec.describe "Partners", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  before do
    sign_in(@user)
  end

  describe "GET #index" do
    it "returns http success" do
      get partners_path(default_params)
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    let(:partner) { create(:partner, organization: @organization, status: :approved) }
    let(:fake_get_return) do
      { "agency" => {
        "families_served" => Faker::Number.number,
        "children_served" => Faker::Number.number,
        "family_zipcodes" => Faker::Number.number,
        "family_zipcodes_list" => [Faker::Number.number]
      } }.to_json
    end

    before do
      allow(DiaperPartnerClient).to receive(:get).with({ id: partner.to_param }, query_params: { impact_metrics: true }).and_return(fake_get_return)
    end

    it "returns http success" do
      get partner_path(default_params.merge(id: partner))
      expect(response).to be_successful
      expect(assigns[:impact_metrics]).to eq(JSON.parse(fake_get_return))
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get new_partner_path(default_params)
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns http success" do
      get edit_partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to be_successful
    end
  end

  describe "POST #import_csv" do
    let(:model_class) { Partner }

    context "with a csv file" do
      let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
      subject { post import_csv_partners_path(default_params), params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "without a csv file" do
      it "redirects to :index" do
        post import_csv_partners_path(default_params)
        expect(response).to be_redirect
      end

      it "presents a flash error message" do
        post import_csv_partners_path(default_params)
        expect(response).to have_error "No file was attached!"
      end
    end

    context "csv file with wrong headers" do
      let(:file) { fixture_file_upload("wrong_headers.csv", "text/csv") }
      subject { post import_csv_partners_path(default_params), params: { file: file } }

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash error message" do
        subject
        expect(response).to have_error "Check headers in file!"
      end
    end
  end

  describe "POST #create" do
    context "successful save" do
      partner_params = { partner: { name: "A Partner", email: "partner@example.com", send_reminders: "false" } }

      it "creates a new partner" do
        post partners_path(default_params.merge(partner_params))
        expect(response).to have_http_status(:found)
      end

      it "redirects to #index" do
        post partners_path(default_params.merge(partner_params))
        expect(response).to redirect_to(partners_path)
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { partner: { name: "", email: "" } }

      it "renders :new" do
        post partners_path(default_params.merge(partner_params))
        expect(response).to render_template(:new)
      end
    end
  end

  describe "POST #update" do
    context "successful save" do
      partner_params = { name: "A Partner", email: "partner@example.com", send_reminders: "false" }

      it "update partner" do
        partner = create(:partner, organization: @organization)
        put partner_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to have_http_status(:found)
      end

      it "redirects to #show" do
        partner = create(:partner, organization: @organization)
        put partner_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to redirect_to(partner_path(partner))
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { name: "", email: "" }

      it "renders :edit" do
        partner = create(:partner, organization: @organization)
        put partner_path(default_params.merge(id: partner, partner: partner_params))
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    it "redirects to #index" do
      delete partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to redirect_to(partners_path)
    end
  end

  describe "POST #invite" do
    it "send the invite" do
      expect(UpdateDiaperPartnerJob).to receive(:perform_now)
      post invite_partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to have_http_status(:found)
    end
  end

  describe "PUT #deactivate" do
    let(:partner) { create(:partner, organization: @organization, status: "approved") }

    context "when the partner successfully deactivates" do
      before do
        response = double

        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)
      end
      it "changes the partner status to deactivated and redirects with flash" do
        put deactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("deactivated")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully deactivated!")
      end
    end

    context "when the partner is not successfully deactivated" do
      before do
        response = double

        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)
      end
      it "fails to change the partner status to deactivated and redirects with flash error message" do
        put deactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("approved")
        expect(response).to redirect_to(partners_path)
        expect(flash[:error]).to eq("#{partner.name} failed to deactivate!")
      end
    end
  end

  describe "GET #approve_application" do
    let(:partner) { create(:partner, organization: @organization) }

    context "successful approval in partner app" do
      before do
        stub_env('PARTNER_REGISTER_URL', 'https://partner-register.com')
        stub_env('PARTNER_KEY', 'partner-key')
        stub_request(:put, "https://partner-register.com/#{partner.id}").to_return({ status: 200, body: 'success', headers: {} })
      end

      it "responds with found status" do
        get approve_application_partner_path(default_params.merge(id: partner.id))
        expect(response).to have_http_status(:found)
      end

      it "redirects to #index" do
        get approve_application_partner_path(default_params.merge(id: partner.id))
        expect(response).to redirect_to(partners_path)
      end

      it "updates partner status to approved" do
        get approve_application_partner_path(default_params.merge(id: partner.id))
        expect(response).to redirect_to(partners_path)
        expect(partner.reload.status).to eq('approved')
      end
    end

    context "failed approval in partner app" do
      before do
        response = double("Response", value: Net::HTTPNotFound)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)
      end

      it "redirects to #index" do
        get approve_application_partner_path(default_params.merge(id: partner.id))
        expect(response).to redirect_to(partners_path)
      end
    end
  end

  describe "PUT #reactivate" do
    context "when the partner successfully reactivates" do
      let(:partner) { create(:partner, organization: @organization, status: "deactivated") }

      before do
        response = double
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)
      end

      it "changes the partner status to approved, partner status on partner app to verified, and redirects with flash" do
        put reactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("approved")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully reactivated!")
      end
    end

    context "when trying to reactivate a partner who is not deactivated " do
      let(:partner) { create(:partner, organization: @organization, status: "approved") }
      before do
        allow(DiaperPartnerClient).to receive(:put)
      end
      it "fails to change the partner status to reactivated and redirects with flash error message" do
        put reactivate_partner_path(default_params.merge(id: partner.id))

        expect(DiaperPartnerClient).not_to have_received(:put)
      end
    end
  end

  describe "POST #recertify_partner" do
    let(:partner) { create(:partner, organization: @organization) }

    context "successful approval in partner app" do
      before do
        stub_env('PARTNER_REGISTER_URL', 'https://partner-register.com')
        stub_env('PARTNER_KEY', 'partner-key')
        stub_request(:put, "https://partner-register.com/#{partner.id}").to_return({ status: 200, body: 'success', headers: {} })
      end

      it "responds with found status" do
        post recertify_partner_partner_path(default_params.merge(id: partner.id))
        expect(response).to have_http_status(:found)
      end

      it "redirects to #index" do
        post recertify_partner_partner_path(default_params.merge(id: partner.id))
        expect(response).to redirect_to(partners_path)
      end

      it "require partner recertification" do
        post recertify_partner_partner_path(default_params.merge(id: partner.id))
        expect(response).to redirect_to(partners_path)
        expect(partner.reload.status).to eq('recertification_required')
      end
    end

    context "failed to update partner records" do
      before do
        response = double("Response", value: Net::HTTPNotFound)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)
      end

      it "redirects to #index" do
        post recertify_partner_partner_path(default_params.merge(id: partner.id))
        expect(response).to redirect_to(partners_path)
      end
    end
  end
end
