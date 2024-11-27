RSpec.describe "Donation Site", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  let(:donation_site) { create(:donation_site) }

  context "When a user views the index page" do
    subject { donation_sites_path }

    it "should show donation sites in alphabetical order" do
      create(:donation_site, name: "Bcd")
      @first = create(:donation_site, name: "Abc")
      @third = create(:donation_site, name: "Cde")
      visit subject
      expect(page).to have_xpath("//table/tbody/tr", count: 3)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.name)
    end

    it "allows the user to quick-create a new donation site only with required fields" do
      visit subject
      donation_site_name = "A Unique Donation Site Name"
      donation_site_address = "1500 Remount Road, Front Royal, VA 22630"

      fill_in "donation_site_name", with: donation_site_name
      fill_in "donation_site_address", with: donation_site_address
      click_button "Create"
      expect(page.find("tbody tr")).to have_content(donation_site_name)
      expect(page.find("tbody tr")).to have_content(donation_site_address)
    end

    it "allows the user to quick-create a new donation site with all fields including optional ones" do
      visit subject
      donation_site_name = "A Unique Donation Site Name"
      donation_site_address = "1500 Remount Road, Front Royal, VA 22630"
      donation_site_contact_name = "John Doe"
      donation_site_phone = "123-456-7890"
      donation_site_email = "asda2@gmail.com"

      fill_in "donation_site_name", with: donation_site_name
      fill_in "donation_site_address", with: donation_site_address
      fill_in "donation_site_contact_name", with: donation_site_contact_name
      fill_in "donation_site_phone", with: donation_site_phone
      fill_in "donation_site_email", with: donation_site_email
      click_button "Create"
      expect(page.find("tbody tr")).to have_content(donation_site_name)
      expect(page.find("tbody tr")).to have_content(donation_site_address)
      expect(page.find("tbody tr")).to have_content(donation_site_contact_name)
      expect(page.find("tbody tr")).to have_content(donation_site_phone)
      expect(page.find("tbody tr")).to have_content(donation_site_email)
    end
  end

  context "When creating a new donation site" do
    subject { new_donation_site_path }

    it "creates a new donation site as a user only with the required fields" do
      visit subject
      donation_site_traits = attributes_for(:donation_site)
      fill_in "Name", with: donation_site_traits[:name], match: :prefer_exact
      fill_in "Address", with: donation_site_traits[:address]
      click_button "Save"

      expect(page.find(".alert")).to have_content "added"
    end

    it "creates a new donation site as a user with all fields available" do
      visit subject
      donation_site_traits = attributes_for(:donation_site)
      fill_in "Name", with: donation_site_traits[:name], match: :prefer_exact
      fill_in "Address", with: donation_site_traits[:address]
      fill_in "Contact Name", with: donation_site_traits[:contact_name]
      fill_in "Phone", with: donation_site_traits[:phone]
      fill_in "Email", with: donation_site_traits[:email]
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
    subject { edit_donation_site_path(donation_site.id) }

    it "updates an existing donation site's Name" do
      visit subject
      fill_in "Name", with: donation_site.name + " new", match: :prefer_exact
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "updates an existing donation site's Address" do
      visit subject
      fill_in "Address", with: "123 Donation Site Way"
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "updates an existing donation site's Contact Name" do
      visit subject
      fill_in "Contact Name", with: "Mr A"
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "updates an existing donation site's Phone" do
      visit subject
      fill_in "Phone", with: "(555) 1122-3322"
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "updates an existing donation site's Email" do
      visit subject
      fill_in "Email", with: "mra_email@gmail.com"
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "does not allow updating to an existing donation site with empty required attributes[Name]" do
      visit subject
      fill_in "Name", with: "", match: :prefer_exact

      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end

    it "does not allow updating to an existing donation site with empty required attributes[Address]" do
      visit subject
      fill_in "Address", with: "", match: :prefer_exact

      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end
end
