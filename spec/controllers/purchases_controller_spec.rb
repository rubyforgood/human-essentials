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
      let!(:storage_location) { create(:storage_location) }
      let(:line_items) { [create(:line_item)] }

      it "redirects to GET#edit on success" do
        post :create, params: default_params.merge(
          purchase: { storage_location_id: storage_location.id,
                      purchased_from: "Google",
                      amount_spent: 10,
                      line_items: line_items }
        )
        expect(response).to redirect_to(purchases_path)
      end

      it "renders GET#new with error on failure" do
        post :create, params: default_params.merge(purchase: { storage_location_id: nil,
                                                               amount_spent: nil })
        expect(response).to be_successful # Will render :new
        expect(flash[:error]).to match(/error/i)
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        purchase = create(:purchase, purchased_from: "Google")
        put :update, params: default_params.merge(id: purchase.id,
                                                  purchase: { purchased_from: "Google" })
        expect(response).to redirect_to(purchases_path)
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: create(:purchase)) }
      it "returns http success" do
        expect(subject).to have_http_status(:success)
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:purchase)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: create(:purchase)) }
      it "redirects to the index" do
        expect(subject).to redirect_to(purchases_path)
      end
    end
  end
end
