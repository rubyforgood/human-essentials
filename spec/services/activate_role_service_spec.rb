RSpec.describe ActivateRoleService, type: :service do
  let(:org) { create(:organization, name: "Org ABC") }
  let(:user) { create(:user, name: "User XYZ", organization: nil) }
  let!(:user_role) { Role.create!(resource_type: "Organization", name: "org_user", resource_id: org.id) }
  let!(:admin_role) { Role.create!(resource_type: "Organization", name: "org_admin", resource_id: org.id) }

  describe "#call" do
    context "when the user role exists" do
      it "should activate the role" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        UsersRole.find_by(user_id: user.id, role_id: user_role.id).update(deactivated: true)

        described_class.call(user_id: user.id, role_id: user_role.id)

        expect(user.reload.has_active_role?(:org_user, org)).to be true
      end

      it "should not activate the admin role when activating user role" do
        AddRoleService.call(user_id: user.id, resource_type: "org_admin", resource_id: org.id)
        role_user = UsersRole.find_by(user_id: user.id, role_id: user_role.id)
        role_user.update(deactivated: true)
        role_admin = UsersRole.find_by(user_id: user.id, role_id: admin_role.id)
        role_admin.update(deactivated: true)

        described_class.call(user_id: user.id, role_id: user_role.id)

        expect(user.reload.has_active_role?(:org_user, org)).to be true
        expect(user.reload.has_active_role?(:org_admin, org)).to be false
      end

      it "should activate the user role when activating admin role" do
        AddRoleService.call(user_id: user.id, resource_type: "org_admin", resource_id: org.id)

        described_class.call(user_id: user.id, role_id: user_role.id)

        expect(user.reload.has_active_role?(:org_user, org)).to be true
        expect(user.reload.has_active_role?(:org_admin, org)).to be true
      end

      it "should work with a type and ID instead of role ID" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)

        described_class.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)

        expect(user.reload.has_active_role?(:org_user, org)).to be true
      end
    end

    context "when not enough information provided" do
      it "should raise an error" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)

        expect { described_class.call(user_id: user.id) }
          .to raise_error("Must provide either a role ID or resource ID!")
      end
    end

    context "when the user role does not exist" do
      it "should raise an error" do
        expect {
          described_class.call(user_id: user.id, role_id: user_role.id)
        }.to raise_error("User User XYZ does not have role for Org ABC!")

        expect(user.reload.has_role?(:org_user, org)).to be false
      end
    end
  end
end
