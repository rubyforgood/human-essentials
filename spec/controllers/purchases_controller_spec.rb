require "rails_helper"

RSpec.describe PurchasesController, type: :controller do
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
      let!(:storage_location) { create(:storage_location, organization: @organization) }
      let(:line_items) { [attributes_for(:line_item)] }
      let(:vendor) { create(:vendor, organization: @organization) }

      context "on success" do
        let(:purchase) do
          { storage_location_id: storage_location.id,
            purchased_from: "Google",
            vendor_id: vendor.id,
            amount_spent_in_cents: 10,
            line_items: line_items }
        end

        it "redirects to GET#edit" do
          post :create, params: default_params.merge(purchase: purchase)
          expect(response).to redirect_to(purchases_path)
        end

        it "accepts :amount_spent_in_cents with dollar signs, commas, and periods" do
          formatted_purchase = purchase.merge(amount_spent_in_cents: "$1,000.54")
          post :create, params: default_params.merge(purchase: formatted_purchase)

          expect(Purchase.last.amount_spent_in_cents).to eq 100_054
        end
      end

      context "on failure" do
        it "renders GET#new with error" do
          post :create, params: default_params.merge(purchase: { storage_location_id: nil, amount_spent_in_cents: nil })
          expect(response).to be_successful # Will render :new
          expect(response).to have_error(/error/i)
        end
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        purchase = create(:purchase, purchased_from: "Google")
        put :update, params: default_params.merge(id: purchase.id, purchase: { purchased_from: "Google" })
        expect(response).to redirect_to(purchases_path)
      end

      it "updates storage quantity correctly" do
        purchase = create(:purchase, :with_items, item_quantity: 5)
        line_item = purchase.line_items.first
        line_item_params = {
          "0" => {
            "_destroy" => "false",
            item_id: line_item.item_id,
            quantity: "10",
            id: line_item.id
          }
        }
        purchase_params = { source: "Purchase Site", line_items_attributes: line_item_params }
        expect do
          put :update, params: default_params.merge(id: purchase.id, purchase: purchase_params)
        end.to change { purchase.storage_location.inventory_items.first.quantity }.by(5)
      end

      describe "when removing a line item" do
        it "updates storage invetory item quantity correctly" do
          purchase = create(:purchase, :with_items, item_quantity: 10)
          line_item = purchase.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "true",
              item_id: line_item.item_id,
              id: line_item.id
            }
          }
          purchase_params = { source: "Purchase Site", line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: purchase.id, purchase: purchase_params)
          end.to change { purchase.storage_location.inventory_items.first.quantity }.by(-10)
        end

        it "deletes inventory item if line item and inventory item quantities are equal" do
          purchase = create(:purchase, :with_items, item_quantity: 1)
          line_item = purchase.line_items.first
          inventory_item = purchase.storage_location.inventory_items.first
          inventory_item.update(quantity: line_item.quantity)
          line_item_params = {
            "0" => {
              "_destroy" => "true",
              item_id: line_item.item_id,
              id: line_item.id
            }
          }
          purchase_params = { source: "Purchase Site", line_items_attributes: line_item_params }
          put :update, params: default_params.merge(id: purchase.id, purchase: purchase_params)
          expect { inventory_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe "when changing storage location" do
        it "updates storage quantity correctly" do
          purchase = create(:purchase, :with_items, item_quantity: 10)
          original_storage_location = purchase.storage_location
          new_storage_location = create(:storage_location)
          line_item = purchase.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "8",
              id: line_item.id
            }
          }
          purchase_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: purchase.id, purchase: purchase_params)
          end.to change { original_storage_location.size }.by(-10) # removes the whole purchase of 10
          expect(new_storage_location.size).to eq 8
        end

        it "rollsback updates if quantity would go below 0" do
          purchase = create(:purchase, :with_items, item_quantity: 10)
          original_storage_location = purchase.storage_location

          # adjust inventory so that updating will set quantity below 0
          inventory_item = original_storage_location.inventory_items.last
          inventory_item.quantity = 5
          inventory_item.save!

          new_storage_location = create(:storage_location)
          line_item = purchase.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "1",
              id: line_item.id
            }
          }
          purchase_params = { storage_location: new_storage_location, line_items_attributes: line_item_params }
          expect do
            put :update, params: default_params.merge(id: purchase.id, purchase: purchase_params)
          end.to raise_error(Errors::InsufficientAllotment)
          expect(original_storage_location.size).to eq 5
          expect(new_storage_location.size).to eq 0
          expect(purchase.reload.line_items.first.quantity).to eq 10
        end
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: create(:purchase, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:purchase, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: create(:purchase, organization: @organization)) }
      it "redirects to the index" do
        expect(subject).to redirect_to(purchases_path)
      end
    end
  end
end
