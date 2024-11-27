RSpec.describe "Layout", type: :system do
  let!(:url_prefix) { "/#{@organization.to_param}" }

  describe "Body CSS Data" do
    it "sets the ID to the controller and the class to the action" do
      sign_in(@user)
      visit url_prefix + "/donations/new"
      expect(page).to have_css("body#donations.new")

      distribution = create(:distribution)
      visit url_prefix + "/distributions/#{distribution.id}/edit"
      expect(page).to have_css("body#distributions.edit")
    end
  end
end
