require "rails_helper"

RSpec.describe "Purchases", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in as a user >" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get purchases_path(default_params.merge(format: response_format))
        response
      end

      before { create(:purchase) }

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe "GET #new" do
      subject do
        get new_purchase_path(default_params)
        response
      end

      it { is_expected.to be_successful }
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
            amount_spent: 10,
            line_items: line_items }
        end

        it "redirects to GET#edit" do
          post purchases_path(default_params.merge(purchase: purchase))
          expect(response).to redirect_to(purchases_path)
        end

        it "accepts :amount_spent_in_cents with dollar signs, commas, and periods" do
          formatted_purchase = purchase.merge(amount_spent: "$1,000.54")
          post purchases_path(default_params.merge(purchase: formatted_purchase))

          expect(Purchase.last.amount_spent_in_cents).to eq 100_054
        end
      end

      context "on failure" do
        it "renders GET#new with error" do
          post purchases_path(default_params.merge(purchase: { storage_location_id: nil, amount_spent: nil }))
          expect(response).to be_successful # Will render :new
          expect(response.body).to include('Failed to create purchase due to')
        end
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        purchase = create(:purchase, purchased_from: "Google")
        put purchase_path(default_params.merge(id: purchase.id, purchase: { purchased_from: "Google" }))
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
          put purchase_path(default_params.merge(id: purchase.id, purchase: purchase_params))
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
            put purchase_path(default_params.merge(id: purchase.id, purchase: purchase_params))
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
          put purchase_path(default_params.merge(id: purchase.id, purchase: purchase_params))
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
            put purchase_path(default_params.merge(id: purchase.id, purchase: purchase_params))
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
            put purchase_path(default_params.merge(id: purchase.id, purchase: purchase_params))
          end.to raise_error(Errors::InsufficientAllotment)
          expect(original_storage_location.size).to eq 5
          expect(new_storage_location.size).to eq 0
          expect(purchase.reload.line_items.first.quantity).to eq 10
        end
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_purchase_path(default_params.merge(id: create(:purchase, organization: @organization)))
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get purchase_path(default_params.merge(id: create(:purchase, organization: @organization)))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      # normal users are not authorized
      it "redirects to the dashboard" do
        delete purchase_path(default_params.merge(id: create(:purchase, organization: @organization)))
        expect(response).to redirect_to(dashboard_path)
      end

      it "does not delete a purchase" do
        purchase = create(:purchase, purchased_from: "Google")
        expect { delete purchase_path(default_params.merge(id: purchase.id)) }.to_not change(Purchase, :count)
      end
    end
  end

  context "While signed in as an organizational admin" do
    before do
      sign_in(@organization_admin)
    end

    describe "DELETE #destroy" do
      it "redirects to the index" do
        delete purchase_path(default_params.merge(id: create(:purchase, organization: @organization)))
        expect(response).to redirect_to(purchases_path)
      end

      it "decreases storage location inventory" do
        purchase = create(:purchase, :with_items, item_quantity: 10)
        storage_location = purchase.storage_location
        expect { delete purchase_path(default_params.merge(id: purchase.id)) }.to change { storage_location.size }.by(-10)
      end

      it "deletes a purchase" do
        purchase = create(:purchase, purchased_from: "Google")
        expect { delete purchase_path(default_params.merge(id: purchase.id)) }.to change(Purchase, :count).by(-1)
      end

      it "displays the proper flash notice" do
        purchase_id = create(:purchase, purchased_from: "Google").id.to_s
        delete purchase_path(default_params.merge(id: purchase_id))
        expect(response).to have_notice "Purchase #{purchase_id} has been removed!"
      end
    end
  end
end
