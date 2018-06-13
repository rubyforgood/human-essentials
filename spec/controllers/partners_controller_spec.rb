

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

  describe "DELETE #destroy" do
    subject { delete :destroy, params: default_params.merge(id: create(:partner, organization: @organization)) }
    it "redirects to #index" do
      expect(subject).to redirect_to(partners_path)
    end
  end
end
