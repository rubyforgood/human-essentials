RSpec.shared_examples "requiring authentication" do 
  it "redirects the user to the sign-in page for CRUD actions" do      
    single_params = { organization_id: object.organization.to_param, id: object.id }

    get :index, params: { organization_id: object.organization.to_param }
    expect(response).to be_redirect
  
    get :new, params: { organization_id: object.organization.to_param }
    expect(response).to be_redirect
  
    post :create, params: { organization_id: object.organization.to_param }
    expect(response).to be_redirect
  
    get :show, params: single_params
    expect(response).to be_redirect

#  FIXME: Not all controllers have `edit` actions (or other), and this should be able to adapt to that 
#    get :edit, params: single_params
#    expect(response).to be_redirect

#    put :update, params: single_params
#    expect(response).to be_redirect
  
#    delete :destroy, params: single_params
#    expect(response).to be_redirect
  end
end

RSpec.shared_examples "requiring authorization" do
	it "Disallows all access for CRUD actions" do
      single_params = { organization_id: object.organization.to_param, id: object.id }
      
      get :index, params: { organization_id: object.organization.to_param }
      expect(response).to have_http_status(403)

      get :new, params: { organization_id: object.organization.to_param }
      expect(response).to have_http_status(403)
      
      get :show, params: single_params
      expect(response).to have_http_status(403)
  
#  FIXME: Not all controllers have `edit` actions, and this should be able to adapt to that 
#      get :edit, params: single_params
#      expect(response).to have_http_status(403)
  
#      put :update, params: single_params
#      expect(response).to have_http_status(403)
  
      post :create, params: { organization_id: object.organization.to_param }
      expect(response).to have_http_status(403)
  
#      delete :destroy, params: single_params
#      expect(response).to have_http_status(403)
	end
end