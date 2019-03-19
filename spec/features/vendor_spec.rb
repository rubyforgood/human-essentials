RSpec.feature "Vendor", type: :feature do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }

  context "When a user views the index page" do
    before(:each) do
      @second = create(:vendor, business_name: "Bcd")
      @first = create(:vendor, business_name: "Abc")
      @third = create(:vendor, business_name: "Cde")
      visit url_prefix + "/vendors"
    end
    scenario "the vendor names are in alphabetical order" do
      expect(page).to have_xpath("//table//tr", count: 4)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.business_name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.business_name)
    end
  end

  scenario "User can create a new vendor instance" do
    visit url_prefix + "/vendors/new"
    vendor_traits = attributes_for(:vendor)
    fill_in "Contact Name", with: vendor_traits[:contact_name]
    fill_in "Business Name", with: vendor_traits[:business_name]
    fill_in "Phone", with: vendor_traits[:phone]

    expect do
      click_button "Save"
    end.to change { Vendor.count }.by(1)

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User add a new vendor instance with empty attributes" do
    visit url_prefix + "/vendors/new"
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User can update the contact info for a vendor" do
    vendor = create(:vendor)
    new_email = "foo@bar.com"
    visit url_prefix + "/vendors/#{vendor.id}/edit"
    fill_in "Phone", with: ""
    fill_in "E-mail", with: new_email
    click_button "Save"

    expect(page.find(".alert")).to have_content "updated"
    expect(page).to have_content(vendor.contact_name)
    expect(page).to have_content(new_email)
  end

  scenario "User updates a vendor with empty attributes" do
    vendor = create(:vendor)
    visit url_prefix + "/vendors/#{vendor.id}/edit"
    fill_in "Business Name", with: ""
    fill_in "Contact Name", with: ""
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  context "When vendor have purchases associated with them already" do
    before(:each) do
      @vendor = create(:vendor)
      create(:purchase, :with_items, created_at: 1.day.ago, item_quantity: 10, amount_spent: 1, vendor: @vendor)
      create(:purchase, :with_items, created_at: 1.week.ago, item_quantity: 15, amount_spent: 1, vendor: @vendor)
    end

    scenario "Existing vendors show in the #index with some summary stats" do
      visit url_prefix + "/vendors"
      expect(page).to have_xpath("//table/tbody/tr/td", text: @vendor.business_name)
      expect(page).to have_xpath("//table/tbody/tr/td", text: "25")
    end

    scenario "Single vendor show semi-detailed stats about purchases" do
      visit url_prefix + "/vendors/#{@vendor.to_param}"
      expect(page).to have_xpath("//table/tr", count: 3)
      expect(page).to have_xpath("//table/tr/td", text: "10")
    end
  end
end
