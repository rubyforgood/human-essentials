RSpec.describe "Help", type: :system do
  let(:partner) { FactoryBot.create(:partner) }
  let(:partner_user) { partner.primary_user }

  before do
    partner.update(status: :approved)
    login_as(partner_user)
  end

  describe "for partner users" do
    it "displays the help page" do
      visit partners_help_path
      expect(page).to have_text("Frequently Asked Questions")
    end
  end
end
