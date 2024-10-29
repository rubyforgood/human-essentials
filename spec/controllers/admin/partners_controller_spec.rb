RSpec.describe Admin::PartnersController, type: :controller do
  let(:organization) { create(:organization) }

  # Use the super_admin instead of organization_admin
  let(:super_admin) { create(:super_admin) }

  # Ensure partners are created before the test
  let!(:partner2) { create(:partner, name: "Bravo", organization: organization) }
  let!(:partner1) { create(:partner, name: "alpha", organization: organization) }
  let!(:partner3) { create(:partner, name: "Zeus", organization: organization) }

  let(:default_params) do
    {organization_id: organization.id}
  end

  context "When logged in as a super admin" do
    before do
      sign_in(super_admin)  # Sign in as the super_admin
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end

      it "assigns partners ordered by name (case-insensitive)" do
        get :index
        expect(assigns(:partners)).to eq([partner1, partner2, partner3].sort_by { |p| p.name.downcase })
      end
    end
  end

  context "When logged in as a non-admin user" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    describe "GET #index" do
      it "redirects to login or unauthorized page" do
        get :index
        expect(response).to be_redirect
      end
    end
  end
end
