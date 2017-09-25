require 'rails_helper'

RSpec.describe AdjustmentsController, type: :controller do

  let(:default_params) {
    { organization_id: @organization.to_param }
  }

  # This should return the minimal set of attributes required to create a valid
  # Adjustment. As you add validations to Adjustment, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    {
      organization_id: @organization.id,
      storage_location_id: create(:storage_location, organization: @organization).id
    }
  }

  let(:invalid_attributes) {
    { organization_id: nil }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # AdjustmentsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe 'while signed in' do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "is successful" do
        adjustment = Adjustment.create! valid_attributes
        get :index, params: default_params, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "is successful" do
        adjustment = create(:adjustment)
        get :show, params: default_params.merge(id: adjustment.to_param), session: valid_session
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "is successful" do
        get :new, params: default_params, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Adjustment" do
          expect {
            post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          }.to change(Adjustment, :count).by(1)
        end

        it "assigns a newly created adjustment as @adjustment" do
          post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          expect(assigns(:adjustment)).to be_a(Adjustment)
          expect(assigns(:adjustment)).to be_persisted
        end

        it "redirects to the index after created adjustment" do
          post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          expect(response).to redirect_to(adjustments_path)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved adjustment as @adjustment" do
          post :create, params: default_params.merge(adjustment: invalid_attributes), session: valid_session
          expect(assigns(:adjustment)).to be_a_new(Adjustment)
        end

        it "re-renders the 'new' template" do
          post :create, params: default_params.merge(adjustment: invalid_attributes), session: valid_session
          expect(response).to render_template("new")
        end
      end
    end
  end
end
