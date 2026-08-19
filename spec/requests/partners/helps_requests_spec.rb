RSpec.describe Partners::HelpsController, type: :request do
  let(:bank) { create(:organization, name: "Essentials Bank", email: "bank@test.com") }
  let(:partner) { create(:partner, :approved, organization_id: bank.id) }
  let(:partner_user) { partner.primary_user }

  before do
    login_as(partner_user)
  end

  describe "for partner users" do
    it "displays the bank's information" do
      get partners_help_path
      # The bank name is wrapped in <strong>, so the sentence is not contiguous text.
      expect(response.body).to include("your essentials bank")
      expect(response.body).to include("Essentials Bank")
      expect(response.body).to include("bank@test.com")
    end
  end
end
