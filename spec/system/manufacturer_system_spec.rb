RSpec.describe "Manufacturer", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  context "When a user views the index page" do
    before(:each) do
      @second = create(:manufacturer, name: "Bcd")
      @first = create(:manufacturer, name: "Abc")
      @third = create(:manufacturer, name: "Cde")
      visit manufacturers_path
    end

    it "alphabetizes the manufacturer names" do
      expect(page).to have_xpath("//table//tr", count: 4)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.name)
    end
  end

  it "allows a user to create a new manufacturer instance" do
    visit new_manufacturer_path
    manufacturer_traits = attributes_for(:manufacturer)
    fill_in "Name", with: manufacturer_traits[:name]

    expect do
      click_button "Save"
    end.to change { Manufacturer.count }.by(1)

    expect(page.find(".alert")).to have_content "added"
  end

  it "allows a user to add a new manufacturer instance with empty attributes" do
    visit new_manufacturer_path
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  it "allows a user to update the contact info for a manufacturer" do
    manufacturer = create(:manufacturer)
    new_name = "New Manufacturer Name"
    visit edit_manufacturer_path(manufacturer.id)
    fill_in "Name", with: new_name
    click_button "Save"

    expect(page.find(".alert")).to have_content "updated"
    expect(page).to have_content(new_name)
  end

  it "allows a user to update a manufacturer with empty attributes" do
    manufacturer = create(:manufacturer)
    visit edit_manufacturer_path(manufacturer.id)
    fill_in "Name", with: ""
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  context "When the Manufacturers have donations associated with them already" do
    before(:each) do
      @manufacturer = create(:manufacturer)
      create(:donation, :with_items, created_at: 1.day.ago, item_quantity: 35, source: Donation::SOURCES[:manufacturer], manufacturer: @manufacturer)
      create(:donation, :with_items, created_at: 1.week.ago, item_quantity: 25, source: Donation::SOURCES[:manufacturer], manufacturer: @manufacturer)
      create(:donation, :with_items, created_at: 1.month.ago, item_quantity: 45, source: Donation::SOURCES[:manufacturer], manufacturer: @manufacturer)
    end

    it "shows existing Manufacturers in the #index with some summary stats" do
      visit manufacturers_path
      expect(page).to have_xpath("//table/tbody/tr/td", text: @manufacturer.name)
      expect(page).to have_xpath("//table/tbody/tr/td", text: "105")
    end

    it "allows single Manufacturers to show semi-detailed stats about donations from that manufacturer" do
      visit manufacturer_path(@manufacturer)
      expect(page).to have_xpath("//tr", count: 4)
    end
  end
end
