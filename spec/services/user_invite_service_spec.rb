RSpec.describe UserInviteService, type: :service, skip_seed: true do
  let(:organization) { FactoryBot.create(:organization) }

  context "with existing user" do
    let!(:user) do
      User.create!(name: "Some Name", email: "email@email.com", password: "blahblah!")
    end
    it "should invite the existing user" do
      expect { described_class.invite(email: "email@email.com", resource: @organization) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "should add roles to existing user" do
      described_class.invite(email: "email@email.com",
        roles: [Role::ORG_USER, Role::ORG_ADMIN],
        resource: organization)
      expect(user).to have_role(Role::ORG_USER, organization)
      expect(user).to have_role(Role::ORG_ADMIN, organization)
      expect(user).not_to have_role(Role::PARTNER, :any)
    end
  end

  context "with a new user" do
    it "should create the user with roles" do
      result = described_class.invite(name: "Another Name",
        email: "email2@email.com",
        roles: [Role::ORG_USER, Role::ORG_ADMIN],
        resource: organization)
      expect(result.name).to eq("Another Name")
      expect(result.email).to eq("email2@email.com")
      expect(result).to have_role(Role::ORG_USER, organization)
      expect(result).to have_role(Role::ORG_ADMIN, organization)
      expect(result).not_to have_role(Role::PARTNER, :any)
    end
  end
end
