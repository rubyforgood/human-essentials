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
    it "returns http success" do
      get partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to be_successful
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

  describe "DELETE #destroy" do
    it "redirects to #index" do
      delete partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to redirect_to(partners_path)
    end
  end

  describe "POST #invite" do
    it "send the invite" do
      expect(UpdateDiaperPartnerJob).to receive(:perform_async)
      post invite_partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to have_http_status(:found)
    end
  end

  describe "PUT #deactivate" do
    let(:partner) { create(:partner, organization: @organization) }

    context "when the partner successfully deactivates" do
      it 'performs a PUT request' do
        response = double
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)
        put deactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("deactivated")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully deactivated!")
      end
    end
  end

  describe "PUT #reactivate" do

    context "when the partner successfully reactivates" do
      let(:partner) { create(:partner, organization: @organization, status: "deactivated") }
      it 'performs a PUT request' do
        response = double
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(DiaperPartnerClient).to receive(:put).and_return(response)

        put reactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("awaiting_review")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully reactivated!")
      end
    end
    context "When partner is not deactivated" do
      let(:partner) { create(:partner, organization: @organization, status: "approved") }
      it 'does not perform a PUT request' do
        allow(DiaperPartnerClient).to receive(:put)

        put reactivate_partner_path(default_params.merge(id: partner.id))

        expect(DiaperPartnerClient).not_to have_received(:put)
      end
    end
  end
end
