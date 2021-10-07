require "spec_helper"

RSpec.describe ConsolidatedLoginDirector do
  let(:director) { ConsolidatedLoginDirector.new }

  let(:user) do
    instance_double(User, email: "bank@example.com", organization: double(name: "A Bank"))
  end

  let(:partner_user) do
    instance_double(Partners::User, email: "partner@example.com", partner: double(name: "A Partner"))
  end

  context "before lookup" do
    it "has defaults for the initial /new page" do
      expect(director.render).to eq :new
      expect(director.layout).to eq "devise"
      expect(director.resource_name).to eq "user"
      expect(director.organizations).to be nil
    end
  end

  context "given a bank user's email" do
    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(Partners::User).to receive(:find_by).and_return(nil)
    end

    it "directs to the bank login" do
      director.lookup("email" => "bank@example.com")

      expect(director.email).to eq "bank@example.com"
      expect(director.render).to eq "users/sessions/new"
      expect(director.layout).to eq "devise"
      expect(director.resource_name).to eq "user"
    end
  end

  context "given a partner user's email" do
    before do
      allow(Partners::User).to receive(:find_by).and_return(partner_user)
      allow(User).to receive(:find_by).and_return(nil)
    end

    it "directs to the partner login" do
      director.lookup("email" => "partner@example.com")

      expect(director.email).to eq "partner@example.com"
      expect(director.render).to eq "partner_users/sessions/new"
      expect(director.layout).to eq "devise_partner_users"
      expect(director.resource_name).to eq "partner_user"
    end
  end

  context "given an email registered for both bank and partner logins" do
    let(:user) do
      instance_double(User, email: "both@example.com", organization: double(name: "A Bank"))
    end

    let(:partner_user) do
      instance_double(Partners::User, email: "both@example.com", partner: double(name: "A Partner"))
    end

    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(Partners::User).to receive(:find_by).and_return(partner_user)
    end

    it "directs the user to pick an organization" do
      director.lookup("email" => "both@example.com")

      expect(director.organization).to eq "Bank" # default to bank option
      expect(director.organizations).to eq [
        ["A Bank", "Bank"],
        ["A Partner", "Partner"]
      ]

      expect(director.email).to eq "both@example.com"
      expect(director.render).to eq :new
      expect(director.layout).to eq "devise"
      expect(director.resource_name).to eq "user"
    end

    context "when the user selects an organization to login to" do
      it "directs to the selected login" do
        director.lookup("email" => "both@example.com", "organization" => "Partner")

        expect(director.email).to eq "both@example.com"
        expect(director.render).to eq "partner_users/sessions/new"
        expect(director.layout).to eq "devise_partner_users"
        expect(director.resource_name).to eq "partner_user"
      end
    end
  end
end
