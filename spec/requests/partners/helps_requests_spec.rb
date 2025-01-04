RSpec.describe Partners::HelpsController, type: :request do
  let(:partner) { FactoryBot.create(:partner) }
  let(:partner_user) { partner.primary_user }
  let(:bank) { partner.organization }

  before do
    partner.update(status: :approved)
    login_as(partner_user)
  end

  describe "for partner users" do
    it "displays the bank's information" do
      get partners_help_path
      expect(response.body).to include("your essentials bank, #{bank.name}")
      expect(response.body).to include(bank.email)
    end
  end
end
