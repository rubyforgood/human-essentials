RSpec.describe DonationsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end
  let(:donation) { create(:donation, organization: @organization) }

  context "While signed in as a normal user >" do
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
      let(:line_items) { [attributes_for(:line_item)] }

      it "redirects to GET#edit on success" do
        post :create, params: default_params.merge(
          donation: { storage_location_id: storage_location.id,
                      donation_site_id: donation_site.id,
                      source: "Donation Site",
                      line_items: line_items }
        )
        expect(response).to redirect_to(donations_path)
      end

      it "renders GET#new with error on failure" do
        post :create, params: default_params.merge(donation: { storage_location_id: nil, donation_site_id: nil, source: nil })
        expect(response).to be_successful # Will render :new
        expect(response).to have_error(/error/i)
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        donation = create(:donation_site_donation)
        put :update, params: default_params.merge(id: donation.id, donation: { source: "Donation Site", donation_site_id: donation.donation_site_id })
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
        donation_params = { source: donation.source, line_items_attributes: line_item_params }
        expect do
          put :update, params: default_params.merge(id: donation.id, donation: donation_params)
        end.to change { donation.storage_location.inventory_items.first.quantity }.by(5)
      end

      describe "when changing storage location" do
        it "updates storage quantity correctly" do
          donation = create(:donation, :with_items, item_quantity: 10)
          original_storage_location = donation.storage_location
          new_storage_location = create(:storage_location)
          line_item = donation.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "8",
              id: line_item.id
            }
          }
          donation_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: donation.id, donation: donation_params)
          end.to change { original_storage_location.size }.by(-10) # removes the whole donation of 10
          expect(new_storage_location.size).to eq 8
        end

        it "rollsback updates if quantity would go below 0" do
          donation = create(:donation, :with_items, item_quantity: 10)
          original_storage_location = donation.storage_location

          # adjust inventory so that updating will set quantity below 0
          inventory_item = original_storage_location.inventory_items.last
          inventory_item.quantity = 5
          inventory_item.save!

          new_storage_location = create(:storage_location)
          line_item = donation.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "1",
              id: line_item.id
            }
          }
          donation_params = { source: donation.source, storage_location: new_storage_location, line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: donation.id, donation: donation_params)
          end.to raise_error(Errors::InsufficientAllotment)
          expect(original_storage_location.size).to eq 5
          expect(new_storage_location.size).to eq 0
          expect(donation.reload.line_items.first.quantity).to eq 10
        end
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
          donation_params = { source: donation.source, line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: donation.id, donation: donation_params)
          end.to change { donation.storage_location.inventory_items.first.quantity }.by(-10)
        end
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: donation.id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: donation.id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: donation.id) }

      # normal users are not authorized
      it "redirects to the dashboard path" do
        expect(subject).to redirect_to(dashboard_path)
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

  context "While signed in as an organization admin >" do
    before do
      sign_in(@organization_admin)
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: donation.id) }
      it "redirects to the index" do
        expect(subject).to redirect_to(donations_path)
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:donation) }

    include_examples "requiring authorization"
    it "redirects the user to the sign-in page for Donation specific actions" do
      single_params = { organization_id: object.organization.to_param, id: object.id }

      patch :add_item, params: single_params
      expect(response).to be_redirect

      patch :remove_item, params: single_params
      expect(response).to be_redirect
    end
  end

  context 'calculating total value of multiple donations' do
    it 'works correctly for multiple line items per donation' do
      donations = [
        create(:donation, :with_items, item_quantity: 1),
        create(:donation, :with_items, item_quantity: 2)
      ]
      value = subject.send(:total_value, donations) # private method, need to use `send`
      expect(value).to eq(300)
    end

    it 'returns zero for an empty array of donations' do
      expect(subject.send(:total_value, [])).to be_zero # private method, need to use `send`
    end
  end

  context 'calculating total money raised for all donations' do
    it 'correctly calculates the total' do
      donations = [
        create(:donation, money_raised: 2),
        create(:donation, money_raised: 3)
      ]
      value = subject.send(:total_money_raised, donations) # private method, need to use `send`
      expect(value).to eq(5)
    end

    it 'returns zero for an empty array of donations' do
      expect(subject.send(:total_money_raised, [])).to be_zero # private method, need to use `send`
    end
  end
end
