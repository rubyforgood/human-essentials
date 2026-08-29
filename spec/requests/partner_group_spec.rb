RSpec.describe "PartnerGroups", type: :request do
  let(:user) { create(:user) }
  let(:partner_group) { create(:partner_group) }

  before do
    sign_in(user)
  end

  describe "DELETE #destroy" do
    context "when partner group has no partners" do
      let!(:partner_group) { create(:partner_group) }
      before { get partners_path + "#nav-partner-groups" }
      it "destroys the partner group" do
        within "#nav-partner-groups" do
          expect(response.body).to have_link("Delete")
        end
        expect {
          delete partner_group_path(partner_group)
        }.to change(PartnerGroup, :count).by(-1)

        expect(flash[:notice]).to eq("Partner Group was successfully deleted.")
        expect(response).to redirect_to(partners_path + "#nav-partner-groups")
      end
    end

    context "when partner group has partners" do
      let!(:partner_group) { create(:partner_group) }

      before do
        create(:partner, partner_group: partner_group)
        get partners_path + "#nav-partner-groups"
      end
      it "does not destroy the partner group, and says why" do
        expect {
          delete partner_group_path(partner_group)
        }.not_to change(PartnerGroup, :count)

        # The message names the group, gives the reason and the next step -- it used to say only
        # "Partner Group cannot be deleted." And it redirects to the groups page rather than a
        # `#nav-partner-groups` anchor from when that list was a tab.
        expect(flash[:alert]).to include("still has partners, so it cannot be deleted")
        expect(flash[:alert]).to include("Move them to another group")
        expect(response).to redirect_to(partner_groups_path)
      end
    end
  end
end
