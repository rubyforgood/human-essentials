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
        let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
        let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_minimum_quantity: 5, on_hand_recommended_quantity: 10) }
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
          expect(flash[:error]).to include("The following items have fallen below the minimum on hand quantity")
          expect(flash[:error]).to include("Item 1")
          expect(flash[:error]).to include("Item 2")
          expect(flash[:alert]).to be_nil
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

    describe "PUT #update" do
      context "when distribution causes inventory quantity to be below recommended quantity" do
        let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_recommended_quantity: 5) }
        let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_recommended_quantity: 5) }
        let(:storage_location) do
          storage_location = create(:storage_location)
          create(:inventory_item, storage_location: storage_location, item: item1, quantity: 20)
          create(:inventory_item, storage_location: storage_location, item: item2, quantity: 20)

          storage_location
        end
        let(:distribution) { create(:distribution, storage_location: storage_location) }
        let(:params) do
          {
            organization_id: @organization.id,
            id: distribution.id,
            distribution: {
              storage_location_id: distribution.storage_location.id,
              line_items_attributes:
                {
                  "0": { item_id: item1.id, quantity: 18 },
                  "1": { item_id: item2.id, quantity: 18 }
                }
            }
          }
        end

        subject { put :update, params: params }

        it "redirects with a flash notice and a flash error" do
          expect(subject).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Distribution updated!")
          expect(flash[:alert]).to eq("The following items have fallen below the recommended on hand quantity: Item 1, Item 2")
        end
      end

      context "when distribution causes inventory quantity to be below minimum quantity" do
        let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:storage_location) do
          storage_location = create(:storage_location)
          create(:inventory_item, storage_location: storage_location, item: item1, quantity: 20)
          create(:inventory_item, storage_location: storage_location, item: item2, quantity: 20)

          storage_location
        end
        let(:distribution) { create(:distribution, storage_location: storage_location) }
        let(:params) do
          {
            organization_id: @organization.id,
            id: distribution.id,
            distribution: {
              storage_location_id: distribution.storage_location.id,
              line_items_attributes:
                {
                  "0": { item_id: item1.id, quantity: 18 },
                  "1": { item_id: item2.id, quantity: 18 }
                }
            }
          }
        end

        subject { put :update, params: params }

        it "redirects with a flash notice and a flash error" do
          expect(subject).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Distribution updated!")
          expect(flash[:error]).to eq("The following items have fallen below the minimum on hand quantity: Item 1, Item 2")
          expect(flash[:alert]).to be_nil
        end
      end

      context "when distribution has items updated for minimum quantity" do
        let(:item1) { create(:item, name: "Item 1", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:item2) { create(:item, name: "Item 2", organization: @organization, on_hand_minimum_quantity: 5) }
        let(:storage_location) do
          storage_location = create(:storage_location)
          create(:inventory_item, storage_location: storage_location, item: item1, quantity: 20)
          create(:inventory_item, storage_location: storage_location, item: item2, quantity: 20)

          storage_location
        end
        let(:distribution) { create(:distribution, :with_items, item: item1, storage_location: storage_location) }
        let(:params) do
          {
            organization_id: @organization.id,
            id: distribution.id,
            distribution: {
              storage_location_id: distribution.storage_location.id,
              line_items_attributes:
                {
                  "0": { item_id: item1.id, quantity: 4 },
                  "1": { item_id: item2.id, quantity: 4 }
                }
            }
          }
        end

        before do
          ActiveJob::Base.queue_adapter = :test
          allow(Flipper).to receive(:enabled?).with(:email_active).and_return(true)
        end

        it "redirects with a flash notice and send send_notification" do
          expected_distribution_changes = {
            removed: [],
            updates: [
              {
                name: item1.name,
                new_quantity: 4,
                old_quantity: 100
              }
            ]
          }

          expect(PartnerMailerJob).to receive(:perform_now).with(@organization.id, distribution.id, "Your Distribution Has Changed", expected_distribution_changes)

          put :update, params: params

          expect(response).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Distribution updated!")
          expect(flash[:error]).to be_nil
          expect(flash[:alert]).to be_nil
        end
      end
    end
  end
end
