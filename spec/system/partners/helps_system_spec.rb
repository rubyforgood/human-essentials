RSpec.describe "Help", type: :system do
  let(:partner) { FactoryBot.create(:partner) }
  let(:partner_user) { partner.primary_partner_user }

  before do
    partner.profile.update(partner_status: :verified)
    login_as(partner_user, scope: :partner_user)
  end

  describe "for partner users" do
    it "displays the help page" do
      visit partners_help_path
      expect(page).to have_text("Frequently Asked Questions")
    end
  end
end
