RSpec.describe "PartnerGroups", type: :request do
  let(:user) { create(:user) }
  let(:partner_group) { create(:partner_group) }

  before do
    sign_in(user)
  end

  describe "DELETE #destroy" do
    it "destroys the requested partner_group" do
      partner_group
      expect {
        delete partner_group_path(partner_group)
      }.to change(PartnerGroup, :count).by(-1)
    end

    it "redirects to partners path with anchor" do
      delete partner_group_path(partner_group)
      expect(response).to redirect_to(partners_path + "#nav-partner-groups")
    end

    it "sets a success notice" do
      delete partner_group_path(partner_group)
      expect(flash[:notice]).to eq("Partner Group was successfully deleted.")
    end
  end
end
