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

RSpec.shared_examples "requiring a authenticated partner user" do
  context 'when the user is not a authenticated partner_user' do
    before do
      sign_out :partner_user
    end

    it 'should redirect to the partner user login page' do
      subject.call
      expect(response).to redirect_to(new_partner_user_session_path)
    end
  end
end

