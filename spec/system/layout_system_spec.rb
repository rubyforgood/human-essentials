RSpec.describe "Layout", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let!(:url_prefix) { "/#{organization.to_param}" }

  describe "Body CSS Data" do
    it "sets the ID to the controller and the class to the action" do
      sign_in(user)
      visit new_donation_path
      expect(page).to have_css("body#donations.new")

      distribution = create(:distribution)
      visit edit_distribution_path(distribution.id)
      expect(page).to have_css("body#distributions.edit")
    end
  end
end
