RSpec.describe "Donation Site", type: :system, js: true do
  before do
    sign_in(@user)
  end

  let(:url_prefix) { "/#{@organization.to_param}" }
  let(:donation_site) { create(:donation_site) }

  context "When a user views the index page" do
    subject { url_prefix + "/donation_sites" }

    it "should show donation sites in alphabetical order" do
      create(:donation_site, name: "Bcd")
      @first = create(:donation_site, name: "Abc")
      @third = create(:donation_site, name: "Cde")
      visit subject
      expect(page).to have_xpath("//table/tbody/tr", count: 3)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.name)
    end

    it "allows the user to quick-create a new donation site" do
      visit subject
      donation_site_name = "A Unique Donation Site Name"
      donation_site_address = "1500 Remount Road, Front Royal, VA 22630"

      fill_in "donation_site_name", with: donation_site_name
      fill_in "donation_site_address", with: donation_site_address
      click_button "Create"
      expect(page.find("tbody tr")).to have_content(donation_site_name)
    end
  end

  context "When creating a new donation site" do
    subject { url_prefix + "/donation_sites/new" }

    it "creates a new donation site as a user" do
      visit subject
      donation_site_traits = attributes_for(:donation_site)
      fill_in "Name", with: donation_site_traits[:name]
      fill_in "Address", with: donation_site_traits[:address]
      click_button "Save"

      expect(page.find(".alert")).to have_content "added"
    end

    it "does not allow creating a new donation site with empty attributes" do
      visit subject
      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "with an existing donation site" do
    subject { url_prefix + "/donation_sites/#{donation_site.id}/edit" }

    it "updates an existing donation site" do
      visit subject
      fill_in "Address", with: donation_site.name + " new"
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "does not allow updating to an existing donation site with empty attributes" do
      visit subject
      fill_in "Name", with: ""
      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end
end
