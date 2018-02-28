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
      let!(:donation_site) { create(:donation_site) }
      let(:line_items) { [create(:line_item)] }

      it "redirects to GET#edit on success" do
        post :create, params: default_params.merge(
          donation: { storage_location_id: storage_location.id,
                      donation_site_id: donation_site.id,
                      source: "Donation Site",
                      line_items: line_items } )
        d = Donation.last
        expect(response).to redirect_to(donations_path)
      end

      it "renders GET#new with error on failure" do
        post :create, params: default_params.merge(donation: { storage_location_id: nil, donation_site_id: nil, source: nil } )
        expect(response).to be_successful # Will render :new
        expect(flash[:error]).to match(/error/i)
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        donation = create(:donation, source: "Donation Site")
        put :update, params: default_params.merge(id: donation.id, donation: { source: "Donation Site" })
        expect(response).to redirect_to(donations_path)
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
      let(:object) { create(:donation, organization: create(:organization) ) }

      include_examples "requiring authorization"

      it "Disallows all access for Donation-specific actions" do
        single_params = { organization_id: object.organization.to_param, id: object.id }

        patch :add_item, params: single_params
        expect(response).to be_redirect

        patch :remove_item, params: single_params
        expect(response).to be_redirect
      end
    end

  end

  context "While not signed in" do
    let(:object) { create(:donation) }

    include_examples "requiring authentication"

    it "redirects the user to the sign-in page for Donation specific actions" do
      single_params = { organization_id: object.organization.to_param, id: object.id }

      patch :add_item, params: single_params
      expect(response).to be_redirect

      patch :remove_item, params: single_params
      expect(response).to be_redirect
    end
  end

end
