RSpec.describe RemoveRoleService, type: :service do
  let(:org) { create(:organization, name: "Org ABC") }
  let(:user) { create(:user, name: "User XYZ", organization: nil) }
  let!(:role) { Role.create!(resource_type: "Organization", name: "org_user", resource_id: org.id) }

  describe "#call" do
    context "when the role exists" do
      it "should remove the role" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        described_class.call(user_id: user.id, role_id: role.id)
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
      end

      it "should remove the admin role when removing user role" do
        AddRoleService.call(user_id: user.id, resource_type: "org_admin", resource_id: org.id)
        described_class.call(user_id: user.id, role_id: role.id)
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
        expect(user.reload.has_role?(:org_admin, org)).to eq(false)
      end

      it "should remove last role if users role is removed" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        UsersRole.set_last_role_for(user, role)
        expect(user.last_role).to eq(role)

        described_class.call(user_id: user.id, role_id: role.id)

        expect(user.reload.has_role?(:org_user, org)).to eq(false)
        expect(user.reload.last_role).to eq(nil)
      end

      it "should work with a type and ID instead of role ID" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        described_class.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
      end
    end

    context "when not enough information provided" do
      it "should raise an error" do
        AddRoleService.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        expect { described_class.call(user_id: user.id) }
          .to raise_error("Must provide either a role ID or resource ID!")
      end
    end

    context "when the role does not exist" do
      it "should raise an error" do
        expect {
          described_class.call(user_id: user.id, role_id: role.id)
        }.to raise_error("User User XYZ does not have role for Org ABC!")
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
      end
    end
  end
end
