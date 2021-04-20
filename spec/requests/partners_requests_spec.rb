RSpec.describe "Partners", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  before do
    sign_in(@user)
  end

  describe "GET #index" do
    subject do
      get partners_path(default_params.merge(format: response_format))
      response
    end

    let!(:partner) { create(:partner, organization: @organization) }

    context "html" do
      let(:response_format) { 'html' }

      it { is_expected.to be_successful }
    end

    context "csv" do
      let(:response_format) { 'csv' }

      let(:fake_get_return) do
        { "agency" => {
          "contact_person" => { name: "A Name" }
        } }.to_json
      end

      it { is_expected.to be_successful }
    end
  end

  describe 'POST #create' do
    subject { -> { post partners_path(default_params.merge(partner_attrs)) } }

    context 'when given valid partner attributes in the params' do
      let(:partner_attrs) do
        {
          partner: FactoryBot.attributes_for(:partner)
        }
      end

      it 'should create a new Partner record' do
        expect { subject.call }.to change { Partner.all.count }.by(1)
      end

      it 'should create a new Partners::Partner record' do
        expect { subject.call }.to change { Partners::Partner.all.count }.by(1)
      end

      it 'redirect to the partners index page' do
        subject.call
        expect(response).to redirect_to(partners_path(default_params))
      end
    end

    context 'when given invalid partner attributes in the params' do
      let(:partner_attrs) do
        {
          partner: {
            name: nil
          }
        }
      end

      it 'should not create a new Partner record' do
        expect { subject.call }.not_to change { Partner.all.count }
      end

      it 'should not create a new Partners::Partner record' do
        expect { subject.call }.not_to change { Partners::Partner.all.count }
      end

      it 'should display the error message' do
        subject.call
        expect(response.body).to include("Failed to add partner due to: ")
      end
    end
  end

  describe "GET #show" do
    subject do
      get partner_path(partner, default_params.merge(format: response_format))
      response
    end

    let(:partner) { create(:partner, organization: @organization, status: :approved) }
    let!(:family1) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner.profile) }
    let!(:family2) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-126', partner: partner.profile) }
    let!(:family3) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner.profile) }

    let!(:child1) { FactoryBot.create_list(:partners_child, 2, family: family1) }
    let!(:child2) { FactoryBot.create_list(:partners_child, 2, family: family3) }

    let(:expected_impact_metrics) do
      {
        families_served: 3,
        children_served: 4,
        family_zipcodes: 2,
        family_zipcodes_list: %w(45612-123 45612-126)
      }
    end

    context "html" do
      let(:response_format) { 'html' }

      it { is_expected.to be_successful }

      context "when the partner is invited" do
        it "includes impact metrics" do
          subject
          expect(assigns[:impact_metrics]).to eq(expected_impact_metrics)
        end
      end

      context "when the partner is uninvited" do
        let(:partner) { create(:partner, organization: @organization, status: :uninvited) }

        it "does not include impact metrics" do
          subject
          expect(assigns[:impact_metrics]).not_to be_present
        end
      end
    end

    context "csv" do
      let(:response_format) { 'csv' }

      it { is_expected.to be_successful }
    end
  end

  describe "GET #approve_partner" do
    subject { -> { get approve_partner_partner_path(id: partner.id, organization_id: partner.organization_id) } }
    let(:partner) { create(:partner) }

    it 'should contain the proper page header' do
      subject.call
      expect(response.body).to include("Partner Approval Request")
      expect(response.body).to include("#{partner.name} - Application Details")
    end

    context 'when the partner is awaiting review' do
      before do
        partner.awaiting_review!
        subject.call
      end

      it 'should show the Approve Partner button' do
        expect(response.body).to include("Approve Partner")
      end
    end

    context 'when the partner is not awaiting review' do
      before do
        partner.invited!
        subject.call
      end

      it 'should show the Approve Partner button' do
        expect(response.body).to include("Approve Partner")
      end
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
      post invite_partner_path(default_params.merge(id: create(:partner, organization: @organization)))
      expect(response).to have_http_status(:found)
    end
  end

  describe "PUT #deactivate" do
    let(:partner) { create(:partner, organization: @organization, status: "approved") }

    context "when the partner successfully deactivates" do
      it "changes the partner status to deactivated and redirects with flash" do
        put deactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("deactivated")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully deactivated!")
      end
    end
  end

  describe "GET #approve_application" do
    subject { -> { get approve_application_partner_path(default_params.merge(id: partner.id)) } }
    let(:partner) { create(:partner, organization: @organization) }
    let(:fake_partner_approval_service) { instance_double(PartnerApprovalService, call: -> {}) }

    before do
      allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
    end

    context 'when the approval was successful' do
      before do
        allow(fake_partner_approval_service).to receive(:errors).and_return([])
        subject.call
      end

      it 'should redirect to the partners index page with a success flash message' do
        expect(response).to redirect_to(partners_path(organization_id: @organization.to_param))
        expect(flash[:notice]).to eq("Partner approved!")
      end
    end

    context 'when the approval failed' do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }
      before do
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
        subject.call
      end

      it 'should redirect to the partners index page with a failure flash message' do
        expect(response).to redirect_to(partners_path(organization_id: @organization.to_param))
        expect(flash[:error]).to eq("Failed to approve partner because: #{fake_error_msg}")
      end
    end
  end

  describe "PUT #reactivate" do
    context "when the partner successfully reactivates" do
      let(:partner) { create(:partner, organization: @organization, status: "deactivated") }

      it "changes the partner status to approved, partner status on partner app to verified, and redirects with flash" do
        put reactivate_partner_path(default_params.merge(id: partner.id))

        expect(partner.reload.status).to eq("approved")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully reactivated!")
      end
    end

    context "when trying to reactivate a partner who is not deactivated " do
      let(:partner) { create(:partner, organization: @organization, status: "approved") }
      it "fails to change the partner status to reactivated and redirects with flash error message" do
        put reactivate_partner_path(default_params.merge(id: partner.id))
      end
    end
  end

  describe "POST #recertify_partner" do
    subject { -> { post recertify_partner_partner_path(default_params.merge(id: partner.id)) } }
    let(:partner) { create(:partner, organization: @organization) }
    let(:fake_service) { instance_double(PartnerRequestRecertificationService, call: -> {}) }

    before do
      allow(PartnerRequestRecertificationService).to receive(:new).with(partner: partner).and_return(fake_service)
    end

    context "when the request for recertification from the partner was successful" do
      before do
        allow(fake_service).to receive_message_chain(:errors, :none?).and_return(true)
      end

      it 'should return back to the partners page with a success flash' do
        subject.call
        expect(flash[:success]).to eq("#{partner.name} recertification successfully requested!")
        expect(response).to redirect_to(partners_path)
      end
    end

    context "when the request for recertification from the partner was NOT successful" do
      before do
        allow(fake_service).to receive_message_chain(:errors, :none?).and_return(false)
      end

      it 'should return back to the partners page with a success flash' do
        subject.call
        expect(flash[:error]).to eq("#{partner.name} failed to update partner records")
        expect(response).to redirect_to(partners_path)
      end
    end
  end
end
