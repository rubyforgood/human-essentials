RSpec.describe "Audits", type: :request do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:valid_attributes) do
    {
      organization_id: organization.id,
      storage_location_id: create(:storage_location, organization: organization).id,
      user_id: create(:organization_admin, organization: organization).id
    }
  end

  let(:invalid_storage_location_attributes) do
    {
      organization_id: organization.id,
      storage_location_id: nil,
      user_id: create(:organization_admin, organization: organization).id
    }
  end

  let(:invalid_attributes) do
    { organization_id: nil }
  end

  let(:valid_session) { {} }

  describe "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "GET #index" do
      it "is successful" do
        Audit.create! valid_attributes
        get audits_path
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "is successful" do
        audit = create(:audit, organization: organization)
        get audits_path(id: audit.to_param)
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "is successful" do
        get new_audit_path
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "is successful if the status of audit is `in_progress`" do
        audit = create(:audit, organization: organization)
        get edit_audit_path(id: audit.to_param)
        expect(response).to be_successful
      end

      it "redirects to #index if the status of audit is not `in_progress`" do
        audit = create(:audit, organization: organization, status: :confirmed)
        get edit_audit_path(id: audit.to_param)
        expect(response).to redirect_to(audits_path)

        audit = create(:audit, organization: organization, status: :finalized)
        get edit_audit_path(id: audit.to_param)
        expect(response).to redirect_to(audits_path)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Audit" do
          expect do
            post audits_path(audit: valid_attributes)
          end.to change(Audit, :count).by(1)
        end

        it "creates a new Audit with status as `in_progress` if `save_progress` is passed as a param" do
          expect do
            post audits_path(audit: valid_attributes, save_progress: '')
            expect(Audit.last.in_progress?).to be_truthy
          end.to change(Audit.in_progress, :count).by(1)
        end

        it "creates a new Audit with status as `confirmed` if `confirm_audit` is passed as a param" do
          expect do
            post audits_path(audit: valid_attributes, confirm_audit: '')
            expect(Audit.last.confirmed?).to be_truthy
          end.to change(Audit.confirmed, :count).by(1)
        end

        it "assigns a newly created audit as @audit" do
          post audits_path(audit: valid_attributes)
          expect(assigns(:audit)).to be_a(Audit)
          expect(assigns(:audit)).to be_persisted
        end

        it "redirects to the #show after created audit" do
          post audits_path(audit: valid_attributes)
          expect(response).to redirect_to(audit_path(Audit.last))
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved audit as @audit" do
          post audits_path(audit: invalid_attributes)
          expect(assigns(:audit)).to be_a_new(Audit)
        end

        it "re-renders the 'new' template" do
          post audits_path(audit: invalid_attributes)
          expect(response).to render_template(:new)
        end

        it "re-renders the 'new' template with an error message when an invalid storage location is given" do
          post audits_path(audit: invalid_storage_location_attributes)
          expect(response).to render_template(:new)
          expect(flash[:error]).to eq("Storage location must exist")
        end
      end
    end

    describe 'POST #finalize' do
      it 'sets the finalize status and saves an event' do
        audit = create(:audit, organization: organization)
        expect(AuditEvent.count).to eq(0)
        post audit_finalize_path(audit_id: audit.to_param)
        expect(audit.reload).to be_finalized
        expect(AuditEvent.count).to eq(1)
      end
    end

    describe "DELETE #destroy" do
      context "with valid params" do
        it "destroys the audit if the audit's status is `in_progress`" do
          audit = create(:audit, organization: organization)
          expect do
            delete audit_path(id: audit.to_param)
          end.to change(Audit, :count).by(-1)
        end

        it "destroys the audit if the audit's status is `confirms`" do
          audit = create(:audit, organization: organization, status: :confirmed)
          expect do
            delete audit_path(id: audit.to_param)
          end.to change(Audit, :count).by(-1)
        end

        it "can not destroy the audit if the audit's status is `finalized`" do
          audit = create(:audit, organization: organization, status: :finalized)
          expect do
            delete audit_path(id: audit.to_param)
          end.to change(Audit, :count).by(0)
        end
      end
    end
  end
end
