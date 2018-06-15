RSpec.feature "Donation Site", type: :feature do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }

  context "When a user views the index page" do
    before(:each) do
      @second = create(:donation_site, name: "Bcd")
      @first = create(:donation_site, name: "Abc")
      @third = create(:donation_site, name: "Cde")
      visit url_prefix + "/donation_sites"
    end
    scenario "the donation sites are in alphabetical order" do
      expect(page).to have_xpath("//table/tbody/tr", count: 3)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.name)
    end
  end

  scenario "User creates a new donation site" do
    visit url_prefix + "/donation_sites/new"
    donation_site_traits = attributes_for(:donation_site)
    fill_in "Name", with: donation_site_traits[:name]
    fill_in "Address", with: donation_site_traits[:address]
    click_button "Create Donation site"

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User creates a new donation site with empty attributes" do
    visit url_prefix + "/donation_sites/new"
    click_button "Create Donation site"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User updates an existing donation site" do
    donation_site = create(:donation_site)
    visit url_prefix + "/donation_sites/#{donation_site.id}/edit"
    fill_in "Address", with: donation_site.name + " new"
    click_button "Update Donation site"

    expect(page.find(".alert")).to have_content "updated"
  end

  scenario "User updates an existing donation site with empty attributes" do
    donation_site = create(:donation_site)
    visit url_prefix + "/donation_sites/#{donation_site.id}/edit"
    fill_in "Name", with: ""
    click_button "Update Donation site"

    expect(page.find(".alert")).to have_content "didn't work"
  end
end
