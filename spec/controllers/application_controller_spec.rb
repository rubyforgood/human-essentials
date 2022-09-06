describe ApplicationController do
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
      let(:user) { create(:super_admin) }

      it "links to the general dashboard" do
        org_name = @organization.short_name
        expect(controller.dashboard_path_from_current_role).to eq "/#{org_name}/dashboard"
      end
    end
  end
end
