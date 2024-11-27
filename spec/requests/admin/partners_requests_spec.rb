RSpec.describe "Admin::Partners", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "When logged in as a super admin" do
    before do
      sign_in(create(:super_admin, organization: nil))
    end

    let(:partner) { create(:partner) }

    describe "GET #index" do
      it "returns http success" do
        get admin_partners_path
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get admin_partner_path(id: partner.id)
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_admin_partner_path(id: partner.id)
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      context "successful save" do
        subject { put admin_partner_path(id: partner.id, partner: { name: "Bar" }) }

        it "updates partner" do
          expect { subject }.to change { partner.reload.name }.to "Bar"
        end

        it "redirects" do
          subject
          expect(response).to be_redirect
        end
      end

      context "unsuccessful save due to empty params" do
        subject { put admin_partner_path(id: partner.id, partner: { name: "" }) }

        it "renders #edit template with error message" do
          expect(subject).to render_template(:edit)
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
