RSpec.describe DistributionsController, type: :controller do
  let!(:current_organization) { create(:organization) }

  describe "GET #print" do
    subject { get :print, params: { organization_id: current_organization, id: create(:distribution).id } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #reclaim" do
    subject { get :reclaim, params: { organization_id: current_organization, id: create(:distribution).id } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #index" do
    subject { get :index, params: { organization_id: current_organization } }
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

      post :create, params: { organization_id: current_organization.short_name,
                              distribution: { storage_location_id: i.id, partner_id: p.id } }
      expect(response).to have_http_status(:redirect)

      d = Distribution.last
      expect(response).to redirect_to(distribution_path(d.id, organization_id: current_organization.short_name))
    end

    it "renders #new again on failure, with notice" do
      post :create, params: { organization_id: current_organization.short_name,
                              distribution: { comment: nil, partner_id: nil, storage_location_id: nil } }
      expect(response).to be_successful
      expect(flash[:notice]).to match(/error/i)
    end
  end

  describe "GET #new" do
    subject { get :new, params:{ organization_id: current_organization.short_name } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #show" do
    subject { get :show, params: { organization_id: current_organization.short_name, id: create(:distribution).id } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

end
