RSpec.describe "Partner Distributions", type: :system, js: true do
  describe "Distributions" do
    let(:partner_user) { partner.primary_user }
    let(:date) { 1.week.from_now }
    let(:past_date) { 1.week.ago }
    let!(:partner) { FactoryBot.create(:partner) }

    before do
      login_as(partner_user)
    end

    it "displays upcoming distributions" do
      FactoryBot.create(:distribution, :with_items, partner: partner, organization: partner.organization, issued_at: date)
      visit partners_distributions_path
      expect(page).to have_content("100")
      expect(page).to have_content(date.strftime("%m/%d/%Y"))
    end

    it "displays prior distributions" do
      FactoryBot.create(:distribution, :with_items, partner: partner, organization: partner.organization,
        issued_at: past_date, item_quantity: 200)
      visit partners_distributions_path
      expect(page).to have_content("200")
      expect(page).to have_content(past_date.strftime("%m/%d/%Y"))
    end
  end
end
