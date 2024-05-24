RSpec.describe AddRoleService, type: :service do
  let(:user) { create(:user, name: "User XYZ") }
  let(:org) { create(:organization, name: "Org ABC") }
  let(:partner) { create(:partner, name: "Partner 123") }

  describe "#call" do
    context "when the role does not yet exist" do
      it "should add the role" do
        described_class.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        expect(user.reload.has_role?(:org_user, org)).to eq(true)
        expect(user.has_role?(:org_admin)).to eq(false)
        expect(user.has_role?(:partner)).to eq(false)
        expect(user.has_role?(:super_admin)).to eq(false)
      end

      it "should add the user role when asked to add admin" do
        described_class.call(user_id: user.id, resource_type: "org_admin", resource_id: org.id)
        expect(user.reload.has_role?(:org_user, org)).to eq(true)
        expect(user.reload.has_role?(:org_admin, org)).to eq(true)
        expect(user.has_role?(:partner)).to eq(false)
        expect(user.has_role?(:super_admin)).to eq(false)
      end

      it "works with a partner" do
        described_class.call(user_id: user.id, resource_type: "partner", resource_id: partner.id)
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
        expect(user.has_role?(:org_admin)).to eq(false)
        expect(user.has_role?(:partner, partner)).to eq(true)
        expect(user.has_role?(:super_admin)).to eq(false)
      end

      it "works with super admin" do
        described_class.call(user_id: user.id, resource_type: "super_admin")
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
        expect(user.has_role?(:org_admin)).to eq(false)
        expect(user.has_role?(:partner)).to eq(false)
        expect(user.has_role?(:super_admin)).to eq(true)
      end
    end

    context "when the role already exists" do
      it "should raise an error" do
        user.add_role(:org_user, org)
        expect {
          described_class.call(user_id: user.id, resource_type: "org_user", resource_id: org.id)
        }.to raise_error("User User XYZ already has role for Org ABC")
        expect(user.reload.has_role?(:org_user, org)).to eq(true)
        expect(user.reload.has_role?(:org_admin)).to eq(false)
        expect(user.reload.has_role?(:partner)).to eq(false)
        expect(user.reload.has_role?(:super_admin)).to eq(false)
      end

      it "should raise an error for super admin" do
        user.add_role(:super_admin)
        expect {
          described_class.call(user_id: user.id, resource_type: "super_admin")
        }.to raise_error("User User XYZ already has super admin role!")
        expect(user.reload.has_role?(:org_user, org)).to eq(false)
        expect(user.reload.has_role?(:org_admin)).to eq(false)
        expect(user.reload.has_role?(:partner)).to eq(false)
        expect(user.reload.has_role?(:super_admin)).to eq(true)
      end
    end
  end
end
