require "rails_helper"

RSpec.describe AdjustmentsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  # This should return the minimal set of attributes required to create a valid
  # Adjustment. As you add validations to Adjustment, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    {
      organization_id: @organization.id,
      storage_location_id: create(:storage_location, organization: @organization).id
    }
  end

  let(:invalid_attributes) do
    { organization_id: nil }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # AdjustmentsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      around do |example|
        travel_to Time.zone.local(2019, 7, 1)
        example.run
        travel_back
      end

      it "is successful" do
        Adjustment.create! valid_attributes.merge(user_id: @user.id)
        get :index, params: default_params, session: valid_session
        expect(response).to be_successful
      end

      context 'when filtering by date' do
        let!(:old_adjustment) { create(:adjustment, created_at: 7.days.ago) }
        let!(:new_adjustment) { create(:adjustment, created_at: 1.day.ago) }

        context 'when date parameters are supplied' do
          it 'only returns the correct objects' do
            get :index, params: default_params.merge(filters: { date_range: date_range_picker_params(3.days.ago, Time.zone.today) })
            expect(assigns(:adjustments)).to contain_exactly(new_adjustment)
          end
        end

        context 'when date parameters are not supplied' do
          it 'returns all objects' do
            get :index, params: default_params
            expect(assigns(:adjustments)).to contain_exactly(old_adjustment, new_adjustment)
          end
        end
      end
    end

    describe "GET #show" do
      it "is successful" do
        adjustment = create(:adjustment, organization: @organization)
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
          expect do
            post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          end.to change(Adjustment, :count).by(1)
        end

        it "assigns a newly created adjustment as @adjustment" do
          post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          expect(assigns(:adjustment)).to be_a(Adjustment)
          expect(assigns(:adjustment)).to be_persisted
        end

        it "assigns a user id from the current user" do
          post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          expect(assigns(:adjustment).user_id).to eq(@user.id)
        end

        it "redirects to the #show after created adjustment" do
          post :create, params: default_params.merge(adjustment: valid_attributes), session: valid_session
          expect(response).to redirect_to(adjustment_path(Adjustment.last))
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
