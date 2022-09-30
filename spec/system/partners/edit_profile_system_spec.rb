RSpec.describe "edit profile page", type: :system do
  let!(:partner) { FactoryBot.create(:partner) }
  let(:partner_user) { partner.primary_partner_user }

  before do
    partner.profile.update(partner_status: :verified)
    login_as(partner_user)
    visit edit_partners_profile_path
  end

  describe "with no social media platfrom filled out and the checkbox is unchecked" do
    it "should display the correct error message", :aggregate_failures do
      fill_in "Website", with: ""
      fill_in "Facebook", with: ""
      fill_in "Twitter", with: ""
      fill_in "Instagram", with: ""
      uncheck "No Social Media Presence"
      click_on "Update Information"

      expect(page).to have_text("You must either provide a social media site or indicate that you have no social media presence")
      expect(page).not_to have_text("No social media presence must be accepted")
    end
  end
end
