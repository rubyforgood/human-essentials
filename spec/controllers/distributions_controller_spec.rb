RSpec.describe DistributionsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "POST #create" do
      context "when distribution causes inventory quantity to be below minimum quantity" do
        let(:item) { create(:item, organization: @organization, on_hand_minimum_quantity: 5) }
        let(:storage_location) { create(:storage_location, :with_items, item: item, item_quantity: 20) }

        let(:params) do
          {
            organization_id: @organization.id,
            distribution: {
              partner_id: @partner.id,
              storage_location_id: storage_location.id,
              line_items_attributes: [
                {
                  "0": { item_id: storage_location.items.first.id, quantity: 18 },
                }
              ]
            }
          }
        end

        subject { post :create, params: params }

        it "redirects with a flash warning" do
          expect(subject).to have_http_status(:redirect)
          expect(flash[:warning]).to be_present
        end
      end
    end
  end
end
