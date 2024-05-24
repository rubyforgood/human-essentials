# == Schema Information
#
# Table name: users_roles
#
#  id      :bigint           not null, primary key
#  role_id :bigint
#  user_id :bigint
#
RSpec.describe UsersRole, type: :model do
  describe "#current_role_for" do
    context "when last_role is nil" do
      context "for org user" do
        it "should return org user" do
          user = create(:user)
          expect(UsersRole.current_role_for(user).name).to eq("org_user")
        end
      end

      context "for org admin" do
        it "should return org admin" do
          user = create(:organization_admin)
          expect(UsersRole.current_role_for(user).name).to eq("org_admin")
        end
      end

      context "for super admin" do
        it "should return super admin" do
          user = create(:super_admin)
          expect(UsersRole.current_role_for(user).name).to eq("super_admin")
        end
      end

      context "for partner user" do
        it "should return partner user" do
          user = create(:partner_user)
          expect(UsersRole.current_role_for(user).name).to eq("partner")
        end
      end
    end
    context "when last_role is not nil" do
      it "should return last role" do
        user = create(:partner_user)

        UsersRole.set_last_role_for(user, user.roles.last)

        user.add_role(Role::ORG_ADMIN, create(:organization))
        expect(UsersRole.current_role_for(user).name).to eq("partner")
      end
    end
  end

  describe "#set_last_role_for" do
    context "when user has the role" do
      it "should set last role" do
        user = create(:partner_user)
        role = user.roles.first

        UsersRole.set_last_role_for(user, role)

        expect(user.last_role).to eq(role)
      end
    end

    context "when user does not have the role" do
      it "should not set last role" do
        user = create(:partner_user)
        role = Role.find_by(name: "org_user")

        UsersRole.set_last_role_for(user, role)
        expect(user.last_role).to eq(nil)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
