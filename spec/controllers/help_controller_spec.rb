RSpec.describe HelpController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  let(:default_params) do
    { organization_name: organization.to_param }
  end

  context "While signed in as a normal user >" do
    before do
      sign_in(user)
    end

    describe "GET #show" do
      subject { get :show, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
      it "does not display help page when the user logs out" do
        sign_out(user)
        expect(subject).to_not be_successful
      end
    end
  end
end
