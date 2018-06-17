RSpec.describe DonationsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

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
                      line_items: line_items }
        )
        d = Donation.last
        expect(response).to redirect_to(donations_path)
      end

      it "renders GET#new with error on failure" do
        post :create, params: default_params.merge(donation: { storage_location_id: nil, donation_site_id: nil, source: nil })
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

      it "updates storage quantity correctly" do
        donation = create(:donation, :with_items, item_quantity: 10)
        line_item = donation.line_items.first
        line_item_params = {
          "0" => {
            "_destroy" => "false",
            item_id: line_item.item_id,
            quantity: "15",
            id: line_item.id
          }
        }
        donation_params = { source: "Donation Site", line_items_attributes: line_item_params }
        expect do
          put :update, params: default_params.merge(id: donation.id, donation: donation_params)
        end.to change { donation.storage_location.inventory_items.first.quantity }.by(5)
      end

      describe "when removing a line item" do
        it "updates storage invetory item quantity correctly" do
          donation = create(:donation, :with_items, item_quantity: 10)
          line_item = donation.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "true",
              item_id: line_item.item_id,
              id: line_item.id
            }
          }
          donation_params = { source: "Donation Site", line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: donation.id, donation: donation_params)
          end.to change { donation.storage_location.inventory_items.first.quantity }.by(-10)
        end

        it "deletes inventory item if line item and inventory item quantities are equal" do
          donation = create(:donation, :with_items, item_quantity: 1)
          line_item = donation.line_items.first
          inventory_item = donation.storage_location.inventory_items.first
          inventory_item.update(quantity: line_item.quantity)
          line_item_params = {
            "0" => {
              "_destroy" => "true",
              item_id: line_item.item_id,
              id: line_item.id
            }
          }
          donation_params = { source: "Donation Site", line_items_attributes: line_item_params }
          put :update, params: default_params.merge(id: donation.id, donation: donation_params)
          expect { inventory_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: create(:donation)) }
      it "returns http success" do
        expect(subject).to have_http_status(:success)
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:donation, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: create(:donation, organization: @organization)) }
      it "redirects to the index" do
        expect(subject).to redirect_to(donations_path)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:donation, organization: create(:organization)) }

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
