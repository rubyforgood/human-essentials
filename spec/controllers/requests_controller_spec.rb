RSpec.describe RequestsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
    
    describe "DELETE #destroy" do
        subject { delete :destroy, params: default_params.merge(id: create(:request, organization: @organization)) }
        it "returns http success" do
            expect(subject).to be_successful
        end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:request, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:request) }

    include_examples "requiring authorization"
  end
end
