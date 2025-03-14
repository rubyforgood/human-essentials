RSpec.describe "Admin::Partners", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "When logged in as a super admin" do
    before do
      sign_in(create(:super_admin, organization: nil))
    end

    let!(:partner1) { create(:partner, name: "Bravo", organization: organization) }
    let!(:partner2) { create(:partner, name: "alpha", organization: organization) }
    let!(:partner3) { create(:partner, name: "Zeus", organization: organization) }

    describe "GET #index" do
      it "returns http success" do
        get admin_partners_path
        expect(response).to be_successful
      end

      it "assigns partners ordered by name (case-insensitive)" do
        get admin_partners_path
        expect(assigns(:partners)).to eq([partner2, partner1, partner3])
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get admin_partner_path(id: partner1.id)
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_admin_partner_path(id: partner1.id)
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      context "successful save" do
        subject { put admin_partner_path(id: partner1.id, partner: { name: "Bar" }) }

        it "updates partner" do
          expect { subject }.to change { partner1.reload.name }.to "Bar"
        end

        it "redirects" do
          subject
          expect(response).to be_redirect
        end
      end

      context "unsuccessful save due to empty params" do
        subject { put admin_partner_path(id: partner1.id, partner: { name: "" }) }

        it "renders #edit template with error message" do
          expect(subject).to render_template(:edit)
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
