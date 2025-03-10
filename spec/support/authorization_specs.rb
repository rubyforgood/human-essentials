RSpec.shared_examples "restricts partner access" do
  context "when signed in as partner" do
    let(:partner) { create(:partner) }
    let(:partner_user) { partner.primary_user }

    before do
      sign_in(partner_user)
    end

    it "redirects partners to their dashboard with a flash message" do
      expect(subject).to redirect_to(partners_dashboard_path)
      expect(flash[:error]).to eq("That screen is not available. Please switch to the correct role and try again.")
    end
  end
end

RSpec.shared_examples "requiring authorization" do |constraints|
  it "redirects the user to the sign-in page for CRUD actions" do
    member_params = { organization_id: object.organization.to_param, id: object.id }
    collection_params = { organization_id: object.organization.to_param }

    (constraints ||= {}).merge!(except: [], only: [])
    skip_these = constraints[:except] + (%i(index new create show edit update destroy) - constraints[:only])

    unless skip_these.include?(:index)
      get :index, params: collection_params
      expect(response).to be_redirect
    end

    unless skip_these.include?(:new)
      get :new, params: collection_params
      expect(response).to be_redirect
    end

    unless skip_these.include?(:create)
      post :create, params: collection_params
      expect(response).to be_redirect
    end

    unless skip_these.include?(:show)
      get :show, params: member_params
      expect(response).to be_redirect
    end

    unless skip_these.include?(:edit)
      get :edit, params: member_params
      expect(response).to be_redirect
    end

    unless skip_these.include?(:update)
      get :update, params: member_params
      expect(response).to be_redirect
    end

    unless skip_these.include?(:destroy)
      delete :destroy, params: member_params
      expect(response).to be_redirect
    end
  end
end
