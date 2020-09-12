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
        let(:item) { create(:item, name: "Item 1", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:storage_location) { create(:storage_location, :with_items, item: item, item_quantity: 20) }
        let(:params) do
          {
            organization_id: @organization.id,
            distribution: {
              partner_id: @partner.id,
              storage_location_id: storage_location.id,
              line_items_attributes:
                {
                  "0": { item_id: storage_location.items.first.id, quantity: 18 }
                }
            }
          }
        end

        subject { post :create, params: params }

        it "redirects with a flash notice and a flash error" do
          expect(subject).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Distribution created!")
          expect(flash[:error]).to eq("The following items have fallen below the minimum on hand quantity: Item 1")
        end
      end

      context "multiple line_items that have inventory quantity below minimum quantity" do
        let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:storage_location) do
          storage_location = create(:storage_location)
          create(:inventory_item, storage_location: storage_location, item: item1, quantity: 20)
          create(:inventory_item, storage_location: storage_location, item: item2, quantity: 20)

          storage_location
        end
        let(:params) do
          {
            organization_id: @organization.id,
            distribution: {
              partner_id: @partner.id,
              storage_location_id: storage_location.id,
              line_items_attributes:
                {
                  "0": { item_id: item1.id, quantity: 18 },
                  "1": { item_id: item2.id, quantity: 18 }
                }
            }
          }
        end

        subject { post :create, params: params }

        it "redirects with a flash notice and a flash error" do
          expect(subject).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Distribution created!")
          expect(flash[:error]).to eq("The following items have fallen below the minimum on hand quantity: Item 1, Item 2")
        end
      end

      context "multiple line_items that have inventory quantity below recommended quantity" do
        let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_recommended_quantity: 5) }
        let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_recommended_quantity: 5) }
        let(:storage_location) do
          storage_location = create(:storage_location)
          create(:inventory_item, storage_location: storage_location, item: item1, quantity: 20)
          create(:inventory_item, storage_location: storage_location, item: item2, quantity: 20)

          storage_location
        end
        let(:params) do
          {
            organization_id: @organization.id,
            distribution: {
              partner_id: @partner.id,
              storage_location_id: storage_location.id,
              line_items_attributes:
                {
                  "0": { item_id: item1.id, quantity: 18 },
                  "1": { item_id: item2.id, quantity: 18 }
                }
            }
          }
        end

        subject { post :create, params: params }

        it "redirects with a flash notice and a flash alert" do
          expect(subject).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Distribution created!")
          expect(flash[:alert]).to eq("The following items have fallen below the recommended on hand quantity: Item 1, Item 2")
        end
      end

    end
  end
end
