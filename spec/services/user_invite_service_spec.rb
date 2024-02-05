RSpec.describe UserInviteService, type: :service, skip_seed: true do
  let(:organization) { FactoryBot.create(:organization) }
  let(:partner) { FactoryBot.create(:partner, organization: organization) }

  before(:each) do
    allow(UserMailer).to receive(:role_added).and_return(double(:mail, deliver_later: nil))
  end

  context "with existing user" do
    let!(:user) do
      User.create!(name: "Some Name", email: "email@email.com", password: "blahblah!")
    end

    it "should raise an error when reinviting an existing user with the same role" do
      expect {
        expect { described_class.invite(email: "email@email.com", resource: @organization) }
          .to raise_error("User already has the requested role!")
      }.not_to change { ActionMailer::Base.deliveries.count }
      expect(UserMailer).not_to have_received(:role_added)
    end

    context "with force: true" do
      it "should reinvite the user" do
        expect { described_class.invite(email: "email@email.com", resource: @organization, force: true) }
          .to change { ActionMailer::Base.deliveries.count }
        expect(UserMailer).not_to have_received(:role_added)
      end
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
      result = nil
      expect {
        result = described_class.invite(name: "Another Name",
          email: "email2@email.com",
          roles: [Role::ORG_USER, Role::ORG_ADMIN],
          resource: organization)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(result.name).to eq("Another Name")
      expect(result.email).to eq("email2@email.com")
      expect(result).to have_role(Role::ORG_USER, organization)
      expect(result).to have_role(Role::ORG_ADMIN, organization)
      expect(result).not_to have_role(Role::PARTNER, :any)
    end

    it "should create the user without name with role" do
      result = nil
      expect {
        result = described_class.invite(name: "",
          email: "email2@email.com",
          roles: [Role::ORG_USER, Role::ORG_ADMIN],
          resource: organization)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(result.name).to eq("")
      expect(result.email).to eq("email2@email.com")
      expect(result).to have_role(Role::ORG_USER, organization)
      expect(result).to have_role(Role::ORG_ADMIN, organization)
    end
  end

  it "should invite a user with the partner role" do
    result = nil
    expect {
      result = described_class.invite(
        name: "Partner User",
        email: "partner@example.com",
        roles: [Role::PARTNER],
        resource: partner
      )
    }.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(result.name).to eq("Partner User")
    expect(result).not_to be_nil
    expect(result.has_role?(:partner, partner)).to be true
  end

  it "should create the user without a name with default role" do
    result = nil
    expect {
      result = described_class.invite(
        name: nil,
        email: "email2@example.com",
        roles: [Role::ORG_USER],
        resource: organization
      )
    }.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(result.name).to eq("Name Not Provided")
    expect(result.email).to eq("email2@example.com")
    expect(result.has_role?(:org_user, organization)).to be true
  end
end
