RSpec.describe DonationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:donation) { create(:donation, organization: organization) }

  context "While signed in as a normal user >" do
    before do
      sign_in(user)
    end

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
      let!(:storage_location) { create(:storage_location) }
      let!(:donation_site) { create(:donation_site) }
      let(:line_items) { [attributes_for(:line_item)] }

      it "redirects to GET#edit on success" do
        post :create, params: {
          donation: { storage_location_id: storage_location.id,
                      donation_site_id: donation_site.id,
                      source: "Donation Site",
                      issued_at: Date.yesterday,
                      line_items: line_items }
        }
        expect(response).to redirect_to(donations_path)
      end

      it "renders GET#new with error on failure" do
        post :create, params: { donation: { storage_location_id: nil, donation_site_id: nil, source: nil } }
        expect(response).to be_successful # Will render :new
        expect(response).to have_error(/error/i)
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        donation = create(:donation_site_donation)
        put :update, params: { id: donation.id, donation: { source: "Donation Site", donation_site_id: donation.donation_site_id } }
        expect(response).to redirect_to(donations_path)
      end

      it "updates storage quantity correctly" do
        donation = create(:donation, :with_items, item_quantity: 10)
        line_item = donation.line_items.first
        line_item_params = {
          "0" => {
            item_id: line_item.item_id,
            quantity: "15",
            id: line_item.id
          }
        }
        donation_params = { source: donation.source, line_items_attributes: line_item_params }
        expect do
          put :update, params: { id: donation.id, donation: donation_params }
        end.to change {
                 View::Inventory.new(donation.organization_id)
                   .quantity_for(storage_location: donation.storage_location_id, item_id: line_item.item_id)
               }.by(5)
      end

      describe "when changing storage location" do
        it "updates storage quantity correctly" do
          donation = create(:donation, :with_items, item_quantity: 10)
          original_storage_location = donation.storage_location
          new_storage_location = create(:storage_location)
          line_item = donation.line_items.first
          line_item_params = {
            "0" => {
              item_id: line_item.item_id,
              quantity: "8",
              id: line_item.id
            }
          }
          donation_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
          expect do
            put :update, params: { id: donation.id, donation: donation_params }
          end.to change { original_storage_location.size }.by(-10) # removes the whole donation of 10
          expect(new_storage_location.size).to eq 8
        end
      end

      describe "when removing a line item" do
        it "updates storage inventory item quantity correctly" do
          item_id = 1
          item_quantity = 10
          donation = create(:donation, :with_items, item: create(:item, id: item_id), item_quantity: item_quantity)
          # if all line items including blanks are deleted line_items_attributes parameter is not sent
          donation_params = { source: donation.source }
          expect do
            put :update, params: { id: donation.id, donation: donation_params }
          end.to change {
                   View::Inventory.new(donation.organization_id)
                     .quantity_for(storage_location: donation.storage_location_id, item_id: item_id)
                 }.by(-1 * item_quantity)
        end
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: { id: donation.id } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: { id: donation.id } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: { id: donation.id } }

      # normal users are not authorized
      it "redirects to the dashboard path" do
        expect(subject).to redirect_to(dashboard_path)
      end
    end
  end

  context "While signed in as an organization admin >" do
    before do
      sign_in(organization_admin)
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: { id: donation.id } }
      it "redirects to the index" do
        expect(subject).to redirect_to(donations_path)
      end
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
