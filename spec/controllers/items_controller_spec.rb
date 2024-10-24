RSpec.describe ItemsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "While signed in" do
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

    describe "GET #edit" do
      subject { get :edit, params: { id: create(:item, organization: organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "PUT #update" do
      context "visible" do
        let(:item) { create(:item, visible_to_partners: false) }
        subject { put :update, params: { id: item.id, item: { value_in_cents: 100, visible_to_partners: true } } }
        it "should update visible_to_partners to true" do
          expect(subject).to redirect_to(items_path)
          expect(item.reload.visible_to_partners).to be true
        end
      end

      context "invisible" do
        let(:item) { create(:item, visible_to_partners: true) }
        subject { put :update, params: { id: item.id, item: { value_in_cents: 100, visible_to_partners: false } } }
        it "should update visible_to_partners to false" do
          expect(subject).to redirect_to(items_path)
          expect(item.reload.visible_to_partners).to be false
        end
      end

      context "request units" do
        before(:each) { Flipper.enable(:enable_packs) }
        let(:item) { create(:item, organization:) }
        let(:unit) { create(:unit, organization:) }
        it "should add new item's request units" do
          expect(item.request_units).to be_empty
          request = put :update, params: { id: item.id, item: { request_unit_ids: [unit.id] } }
          expect(request).to redirect_to(items_path)
          expect(response).not_to have_error
          expect(item.request_units.reload.pluck(:name)).to match_array [unit.name]
        end

        it "should remove item request units" do
          # add an existing unit
          create(:item_unit, item:, name: unit.name)
          expect(item.request_units.size).to eq 1
          request = put :update, params: { id: item.id, item: { request_unit_ids: [""] } }
          expect(response).not_to have_error
          expect(request).to redirect_to(items_path)
          expect(item.request_units.reload).to be_empty
        end

        it "should add and remove request units at the same time" do
          # attach a different unit to the item
          unit_to_remove = create(:unit, organization:)
          create(:item_unit, item:, name: unit_to_remove.name)
          expect(item.request_units.pluck(:name)).to match_array [unit_to_remove.name]
          request = put :update, params: { id: item.id, item: { request_unit_ids: [unit.id] } }
          expect(response).not_to have_error
          expect(request).to redirect_to(items_path)
          # We should have removed the existing unit and replaced it with the new one
          expect(item.request_units.reload.pluck(:name)).to match_array [unit.name]
        end
      end
    end

    describe "GET #show" do
      subject { get :show, params: { id: create(:item, organization: organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: { id: create(:item, organization: organization) } }
      it "redirects to #index" do
        expect(subject).to redirect_to(items_path)
      end
    end

    describe "PATCH #restore" do
      context "with a soft-deleted item" do
        let!(:item) { create(:item, :inactive) }

        it "re-activates the item" do
          expect do
            patch :restore, params: { id: item.id }
          end.to change { Item.active.size }.by(1)
        end
      end

      context "with an active item" do
        let!(:item) { create(:item, :active) }
        it "does nothing" do
          expect do
            patch :restore, params: { id: item.id }
          end.to change { Item.active.size }.by(0)
        end
      end

      context "with another organizations item" do
        let!(:external_item) { create(:item, :inactive, organization: create(:organization)) }
        it "does nothing" do
          expect do
            patch :restore, params: { id: external_item.id }
          end.to change { Item.active.size }.by(0)
        end
      end
    end

    describe "POST #create" do
      let(:item_params) do
        {
          item: {
            name: "Really Good Item",
            partner_key: create(:base_item).partner_key,
            value_in_cents: 1001,
            package_size: 5,
            distribution_quantity: 30
          }
        }
      end

      context "with valid params" do
        it "should create an item" do
          expect do
            post :create, params: item_params
          end.to change { Item.count }.by(1)
        end

        it "should accept params with dollar signs, periods, and commas" do
          item_params["value_in_cents"] = "$5,432.10"
          post :create, params: item_params

          expect(response).not_to have_error
        end

        it "should accept request_unit ids and create request_units" do
          Flipper.enable(:enable_packs)
          unit = create(:unit, organization: organization)
          item_params[:item] = item_params[:item].merge({request_unit_ids: [unit.id]})
          post :create, params: item_params
          expect(response).not_to have_error
          newly_created_item = Item.last
          expect(newly_created_item.request_units.pluck(:name)).to match_array [unit.name]
        end

        it "should redirect to the item page" do
          post :create, params: item_params

          expect(response).to redirect_to items_path
          expect(response).to have_notice
        end
      end

      context "with invalid params" do
        let(:bad_params) do
          { item: { bad: "params" } }
        end

        it "should show an error" do
          post :create, params: bad_params

          expect(response).to have_error
        end
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:item, organization: create(:organization)) }
      include_examples "requiring authorization"
    end

    describe "PATCH #remove_category" do
      let(:item_category) { create(:item_category) }
      let!(:item) { create(:item, item_category: item_category) }

      it "should remove an item's category" do
        patch :remove_category, params: { id: item.id }
        expect(item.reload.item_category).to be_nil
      end

      it "should redirect to the previous category page" do
        patch :remove_category, params: { id: item.id }

        expect(response).to redirect_to item_category_path(id: item_category.id)
        expect(response).to have_notice
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:item) }

    include_examples "requiring authorization"
  end
end
