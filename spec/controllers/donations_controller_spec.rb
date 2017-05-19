RSpec.describe DonationsController, type: :controller do

  let(:default_params) {
    { organization_id: @organization.to_param }
  }

  context "While signed in >" do
  
  
    before do
      sign_in(@user)
    end
  
    describe "GET #index" do
      subject { get :index, params: default_params }
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
  
    describe "POST#create" do
      let!(:storage_location) { create(:storage_location) }
      let!(:dropoff_location) { create(:dropoff_location) }
  
      it "redirects to GET#edit on success" do
        post :create, params: default_params.merge(donation: { storage_location_id: storage_location.id, dropoff_location_id: dropoff_location.id, source: "foo" })
        d = Donation.last
        expect(response).to redirect_to(edit_donation_path(d))
      end
  
      it "renders GET#new with notice on failure" do
        post :create, params: default_params.merge(donation: { storage_location_id: nil, dropoff_location_id: nil, source: nil } )
        expect(response).to be_successful # Will render :new
        expect(flash[:notice]).to match(/error/i)
      end
    end
  
    describe "PUT#update" do
      it "redirects to #show" do
        donation = create(:donation, source: "bar")
        put :update, params: default_params.merge(id: donation.id, donation: { source: "foo" })
        expect(response).to redirect_to(donation_path(donation))
      end
    end
  
    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: create(:donation)) }
      it "returns http success" do
        expect(subject).to have_http_status(:success)
      end
    end
  
    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:donation)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  
    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: create(:donation)) }
      it "redirects to the index" do
        expect(subject).to redirect_to(donations_path)
      end
    end

    context "Looking at a different organization" do
      it "Disallows all access" do
        other_org = create(:organization)
        get :index, params: { organization_id: other_org.to_param }
        expect(response).to redirect_to(root_path)
      end
    end

  end

  context "While not signed in" do
  end

end
