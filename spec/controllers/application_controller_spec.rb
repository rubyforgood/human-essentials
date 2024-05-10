RSpec.describe ApplicationController, skip_seed: true do
  let(:organization) { create(:organization, skip_items: true) }

  describe "current_organization" do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:current_role).and_return(user.roles.first)
    end

    context "As a partner user" do
      let(:user) { create(:partners_user) }
      it "should return nil" do
        expect(controller.current_organization).to eq(nil)
      end
    end

    context "As an org user" do
      let(:org) { create(:organization, skip_items: true) }
      let(:org2) { create(:organization, skip_items: true) }
      let(:user) { create(:user, organization: org) }
      before(:each) do
        user.add_role(Role::ORG_USER, org2) # add a second role
      end
      it "should return the first org role" do
        expect(controller.current_organization).to eq(org)
      end

      context "with a changed current role" do
        before(:each) do
          allow(controller).to receive(:current_role).and_return(user.roles.last)
        end
        it "should return the first org role" do
          expect(controller.current_organization).to eq(org2)
        end
      end
    end
  end

  describe "current_partner" do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:current_role).and_return(user.roles.first)
    end

    context "As an org user" do
      let(:user) { create(:user, organization: organization) }
      it "should return nil" do
        expect(controller.current_partner).to eq(nil)
      end
    end

    context "As a partner user" do
      let(:partner) { create(:partner, organization: organization) }
      let(:partner2) { create(:partner, organization: organization) }
      let(:user) { create(:partners_user, partner: partner) }
      before(:each) do
        user.add_role(Role::PARTNER, partner2) # add a second role
      end
      it "should return the first partner role" do
        expect(controller.current_partner).to eq(partner)
      end

      context "with a changed current role" do
        before(:each) do
          allow(controller).to receive(:current_role).and_return(user.roles.last)
        end
        it "should return the first partner role" do
          expect(controller.current_partner).to eq(partner2)
        end
      end
    end
  end

  describe "dashboard_path_from_current_role" do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:current_role).and_return(user.roles.first)
    end

    context "As a super admin" do
      let(:user) { create(:super_admin) }

      it "links to the admin dashboard" do
        allow(controller).to receive(:current_role)
          .and_return(user.roles.find { |r| r.name == Role::SUPER_ADMIN.to_s })
        expect(controller.dashboard_path_from_current_role).to match %r{/admin/dashboard.*}
      end
    end

    context "As a user without super admin status" do
      let(:user) { create(:super_admin, organization: organization) }

      it "links to the general dashboard" do
        org_name = organization.short_name
        expect(controller.dashboard_path_from_current_role).to eq "/#{org_name}/dashboard"
      end
    end
  end
end
