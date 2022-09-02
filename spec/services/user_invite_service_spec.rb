RSpec.describe UserInviteService, type: :service, skip_seed: true do
  let(:organization) { FactoryBot.create(:organization) }

  context "with existing user" do
    let!(:user) do
      User.create!(name: "Some Name", email: "email@email.com", password: "blahblah!")
    end
    it "should invite the existing user" do
      allow(User).to receive(:invite!).and_call_original
      result = described_class.invite(email: "email@email.com")
      expect(result.id).to eq(user.id)
      expect(User).to have_received(:invite!)
    end

    it "should add roles to existing user" do
      described_class.invite(email: "email@email.com",
        roles: %i[org_user org_admin],
        resource: organization)
      expect(user).to have_role(:org_user, organization)
      expect(user).to have_role(:org_admin, organization)
      expect(user).not_to have_role(:partner, :any)
    end
  end

  context "with a new user" do
    it "should create the user with roles" do
      result = described_class.invite(name: "Another Name",
        email: "email2@email.com",
        roles: %i[org_user org_admin],
        resource: organization)
      expect(result.name).to eq("Another Name")
      expect(result.email).to eq("email2@email.com")
      expect(user).to have_role(:org_user, organization)
      expect(user).to have_role(:org_admin, organization)
      expect(user).not_to have_role(:partner, :any)
    end
  end
end
