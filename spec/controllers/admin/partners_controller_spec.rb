RSpec.describe Admin::PartnersController, type: :controller do
  context "When logged in as a super admin" do
    before do
      sign_in(@super_admin)
    end

    let(:partner) { create(:partner) }

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get :show, params: { id: partner.id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get :edit, params: { id: partner.id }
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      context "successful save" do
        subject { put :update, params: { id: partner.id, partner: { name: "Bar" } } }

        it "updates partner" do
          expect { subject }.to change { partner.reload.name }.to "Bar"
        end

        it "redirects" do
          expect(subject).to be_redirect
        end
      end

      context "unsuccessful save due to empty params" do
        subject { put :update, params: { id: partner.id, partner: { name: "" } } }

        it "renders #edit template with error message" do
          expect(subject).to render_template(:edit)
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
