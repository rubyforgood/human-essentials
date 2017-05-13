

RSpec.describe DonationsController, type: :controller do
  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #new" do
    subject { get :new }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "POST#create" do
    let!(:inventory){ create(:inventory) }
    let!(:dropoff_location) { create(:dropoff_location) }

    it "redirects to GET#edit on success" do
      post :create, params: { donation: { inventory_id: inventory.id, dropoff_location_id: dropoff_location.id, source: "foo" } }
      d = Donation.last
      expect(response).to redirect_to(edit_donation_path(d))
    end

    it "renders GET#new with notice on failure" do
      post :create, params: { donation: { inventory_id: nil, dropoff_location_id: nil, source: nil } }
      expect(response).to be_successful # Will render :new
      expect(flash[:notice]).to match(/error/i)
    end
  end

  describe "PUT#update" do
    it "redirects to #show" do
      donation = create(:donation, source: "bar")
      put :update, params: { id: donation.id, donation: { source: "foo"} }
      expect(response).to redirect_to(donation_path(donation))
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: create(:donation) } }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:donation) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: create(:donation) } }
    it "redirecst to the index" do
      expect(subject).to redirect_to(donations_path)
    end
  end


end
