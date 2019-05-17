RSpec.describe PartnersController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  before do
    sign_in(@user)
  end

  describe "GET #index" do
    subject { get :index, params: default_params }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #show" do
    subject { get :show, params: default_params.merge(id: create(:partner, organization: @organization)) }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #new" do
    subject { get :new, params: default_params }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: default_params.merge(id: create(:partner, organization: @organization)) }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "POST #import_csv" do
    let(:model_class) { Partner }
    it_behaves_like "csv import"
  end

  describe "POST #create" do
    context "successful save" do
      partner_params = { partner: { name: "A Partner", email: "partner@example.com" } }
      subject { post :create, params: default_params.merge(partner_params) }

      it "creates a new partner" do
        expect { subject }.to change(Partner, :count).by(1)
      end

      it "redirects to #index" do
        expect(subject).to redirect_to(partners_path)
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { partner: { name: "", email: "" } }
      subject { post :create, params: default_params.merge(partner_params) }

      it "renders :new" do
        expect(subject).to render_template(:new)
      end
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: default_params.merge(id: create(:partner, organization: @organization)) }
    it "redirects to #index" do
      expect(subject).to redirect_to(partners_path)
    end
  end

  describe "POST #invite" do
    subject { post :invite, params: default_params.merge(id: create(:partner, organization: @organization)) }
    it "send the invite" do
      expect(UpdateDiaperPartnerJob).to receive(:perform_async)
      subject
    end
  end
end
