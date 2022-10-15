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
    context "for org user" do
      it "should return org user" do
        user = FactoryBot.create(:user)
        expect(described_class.current_role_for(user).name).to eq("org_user")
      end
    end

    context "for org admin" do
      it "should return org admin" do
        user = FactoryBot.create(:organization_admin)
        expect(described_class.current_role_for(user).name).to eq("org_admin")
      end
    end

    context "for super admin" do
      it "should return super admin" do
        user = FactoryBot.create(:super_admin)
        expect(described_class.current_role_for(user).name).to eq("super_admin")
      end
    end

    context "for partner user" do
      it "should return partner user" do
        user = FactoryBot.create(:partner_user)
        expect(described_class.current_role_for(user).name).to eq("partner")
      end
    end
  end
end
