RSpec.feature "Requests", type: :feature do
  before do
    sign_in(@user)
    @request = create(:request, organization: @organization)
    @storage_location = create(:storage_location, organization: @organization)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "While viewing the requests index page" do
    before(:each) do
      visit url_prefix + "/requests"
    end

    scenario "the requests are listed" do
      expect(page).to have_xpath("//h1", text: "Requests")
    end
  end

  context "While viewing the request page" do
    scenario "the request is shown", js: true do
      visit url_prefix + "/requests/#{@request.id}"
      expect(page).to have_content("Request from #{@request.partner.name}")
    end

    scenario "the request is fullfillable", js: true do
      visit url_prefix + "/requests/#{@request.id}"
      click_link "Fullfill request"
      select @storage_location.name, from: "From storage location"
      fill_in "Comment", with: "Take my wipes... please"
      click_button "Preview Distribution"
      expect(page).to have_content "Distribution Manifest for"
      click_button "Confirm Distribution"
      expect(page).to have_content "Distribution created"
    end
  end
end
