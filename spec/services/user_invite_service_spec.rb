RSpec.describe UserInviteService, type: :service do
  let(:organization) { create(:organization) }
  let(:partner) { create(:partner, organization: organization) }

  before(:each) do
    allow(UserMailer).to receive(:role_added).and_return(double(:mail, deliver_later: nil))
  end

  context "with existing user" do
    let!(:user) do
      create(:user, email: "email@email.com", organization: organization)
    end

    it "should raise an error when reinviting an existing user with the same role" do
      expect {
        described_class.invite(email: user.email, resource: organization)
      }.to raise_error("User already has the requested role!")
        .and not_change { ActionMailer::Base.deliveries.count }

      expect(UserMailer).not_to have_received(:role_added)
    end

    context "with force: true" do
      it "should reinvite the user" do
        expect { described_class.invite(email: "email@email.com", resource: organization, force: true) }
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
      expect {
        @result = UserInviteService.invite(
          email: "email2@email.com",
          roles: [Role::PARTNER],
          resource: partner
        )
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      user = User.find_by(email: "email2@email.com")
      expect(user.display_name).to eq("Name Not Provided")
      expect(user.reload.name).to be_nil
      expect(user.name).to be_nil
      expect(user.name).not_to eq("")
      expect(user.email).to eq("email2@email.com")
      expect(user).to have_role(Role::PARTNER, partner)
    end
  end

  it "should invite a user with name and partner role" do
    expect {
      @result = UserInviteService.invite(
        name: "Partner User",
        email: "partner@example.com",
        roles: [Role::PARTNER],
        resource: partner
      )
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    user = User.find_by(email: "partner@example.com")
    expect(user.name).to eq("Partner User")
    expect(user).to be_truthy
    expect(user).not_to be_nil
    expect(user).to have_role(Role::PARTNER, partner)
  end

  it "should invite a user with name '' with default role" do
    expect {
      @result = UserInviteService.invite(
        name: "",
        email: "partner@example.com",
        roles: [Role::ORG_USER],
        resource: organization
      )
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    user = User.find_by(email: "partner@example.com")
    expect(user.name).to be_nil
    expect(user.display_name).to eq("Name Not Provided")
    expect(user).to be_truthy
    expect(user).to have_role(Role::ORG_USER, organization)
  end

  it "should create the user with name nil with default role" do
    result = nil
    expect {
      result = described_class.invite(
        name: nil,
        email: "email2@example.com",
        roles: [Role::ORG_USER],
        resource: organization
      )
    }.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(result.reload.display_name).to eq("Name Not Provided")
    expect(result.name).to be_nil
    expect(result.email).to eq("email2@example.com")
    expect(result.has_role?(:org_user, organization)).to be true
  end

  # simulating a blank name specifically in as "" such as a form submission would do.
  it "should create the user with name '' with default role" do
    result = nil
    expect {
      result = described_class.invite(
        name: "",
        email: "email2@example.com",
        roles: [Role::ORG_USER],
        resource: organization
      )
    }.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(result.display_name).to eq("Name Not Provided")
    expect(result.name).to be_nil
    expect(result.email).to eq("email2@example.com")
    expect(result.has_role?(:org_user, organization)).to be true
  end
end
