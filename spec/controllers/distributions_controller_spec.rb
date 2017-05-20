RSpec.describe DistributionsController, type: :controller do
  let(:default_params) {
    { organization_id: @organization.to_param }
  }

  context "While signed in" do
    before do
      sign_in(@user)
    end
  
    describe "GET #print" do
      subject { get :print, params: default_params.merge({ id: create(:distribution).id }) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  
    describe "GET #reclaim" do
      subject { get :reclaim, params: default_params.merge({ organization_id: @organization, id: create(:distribution).id }) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  
    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  
    describe "POST #create" do
      it "redirects to #show on success" do
        i = create(:storage_location)
        p = create(:partner)
  
        expect(i).to be_valid
        expect(p).to be_valid
  
        post :create, params: default_params.merge(distribution: { storage_location_id: i.id, partner_id: p.id })
        expect(response).to have_http_status(:redirect)
  
        d = Distribution.last
        expect(response).to redirect_to(distribution_path(d.id, organization_id: @organization.short_name))
      end
  
      it "renders #new again on failure, with notice" do
        post :create, params:default_params.merge(distribution: { comment: nil, partner_id: nil, storage_location_id: nil })
        expect(response).to be_successful
        expect(flash[:notice]).to match(/error/i)
      end
    end
  
    describe "GET #new" do
      subject { get :new, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  
    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:distribution).id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:distribution, organization: create(:organization) ) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:distribution) }

    include_examples "requiring authentication"
  end

end
