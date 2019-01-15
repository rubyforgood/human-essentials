require 'rails_helper'

RSpec.describe AuditsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  let(:valid_attributes) do
    {
      organization_id: @organization.id,
      storage_location_id: create(:storage_location, organization: @organization).id,
      user_id: create(:organization_admin, organization: @organization).id
    }
  end

  let(:invalid_attributes) do
    { organization_id: nil }
  end

  let(:valid_session) { {} }

  describe "while signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    describe "GET #index" do
      it "is successful" do
        Audit.create! valid_attributes
        get :index, params: default_params, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "is successful" do
        audit = create(:audit, organization: @organization)
        get :show, params: default_params.merge(id: audit.to_param), session: valid_session
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "is successful" do
        get :new, params: default_params, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "is successful if the status of audit is `in_progress`" do
        audit = create(:audit, organization: @organization)
        get :edit, params: default_params.merge(id: audit.to_param), session: valid_session
        expect(response).to be_successful
      end

      it "redirects to #index if the status of audit is not `in_progress`" do
        audit = create(:audit, organization: @organization, status: :confirmed)
        get :edit, params: default_params.merge(id: audit.to_param), session: valid_session
        expect(response).to redirect_to(audits_path)

        audit = create(:audit, organization: @organization, status: :finalized)
        get :edit, params: default_params.merge(id: audit.to_param), session: valid_session
        expect(response).to redirect_to(audits_path)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Audit" do
          expect do
            post :create, params: default_params.merge(audit: valid_attributes), session: valid_session
          end.to change(Audit, :count).by(1)
        end

        it "creates a new Audit with status as `in_progress` if `save_progress` is passed as a param" do
          expect do
            post :create, params: default_params.merge(audit: valid_attributes, save_progress: ''), session: valid_session
            expect(Audit.last.in_progress?).to be_truthy
          end.to change(Audit.in_progress, :count).by(1)
        end

        it "creates a new Audit with status as `confirmed` if `confirm_audit` is passed as a param" do
          expect do
            post :create, params: default_params.merge(audit: valid_attributes, confirm_audit: ''), session: valid_session
            expect(Audit.last.confirmed?).to be_truthy
          end.to change(Audit.confirmed, :count).by(1)
        end

        it "assigns a newly created audit as @audit" do
          post :create, params: default_params.merge(audit: valid_attributes), session: valid_session
          expect(assigns(:audit)).to be_a(Audit)
          expect(assigns(:audit)).to be_persisted
        end

        it "redirects to the #show after created audit" do
          post :create, params: default_params.merge(audit: valid_attributes), session: valid_session
          expect(response).to redirect_to(audit_path(Audit.last))
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved audit as @audit" do
          post :create, params: default_params.merge(audit: invalid_attributes), session: valid_session
          expect(assigns(:audit)).to be_a_new(Audit)
        end

        it "re-renders the 'new' template" do
          post :create, params: default_params.merge(audit: invalid_attributes), session: valid_session
          expect(response).to render_template(:new)
        end
      end
    end

    describe "DELETE #destroy" do
      context "with valid params" do
        it "destroys the audit if the audit's status is `in_progress`" do
          audit = create(:audit, organization: @organization)
          expect do
            delete :destroy, params: default_params.merge(id: audit.to_param), session: valid_session
          end.to change(Audit, :count).by(-1)
        end

        it "destroys the audit if the audit's status is `confirms`" do
          audit = create(:audit, organization: @organization, status: :confirmed)
          expect do
            delete :destroy, params: default_params.merge(id: audit.to_param), session: valid_session
          end.to change(Audit, :count).by(-1)
        end

        it "can not destroy the audit if the audit's status is `finalized`" do
          audit = create(:audit, organization: @organization, status: :finalized)
          expect do
            delete :destroy, params: default_params.merge(id: audit.to_param), session: valid_session
          end.to change(Audit, :count).by(0)
        end
      end
    end
  end
end
