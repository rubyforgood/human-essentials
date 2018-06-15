RSpec.feature "Partner management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "When a user views the index page" do
    before(:each) do
      @second = create(:partner, name: "Bcd")
      @first = create(:partner, name: "Abc")
      @third = create(:partner, name: "Cde")
      visit url_prefix + "/partners"
    end
    scenario "the partner agency names are in alphabetical order" do
      expect(page).to have_css("table tr", count: 4)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.name)
    end
  end

  scenario "User can add a new partner" do
    visit url_prefix + "/partners/new"
    fill_in "Name", with: "Frank"
    fill_in "E-mail", with: "frank@frank.com"
    click_button "Create Partner"

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User creates a new partner with empty name" do
    visit url_prefix + "/partners/new"
    click_button "Create Partner"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User can update a partner" do
    partner = create(:partner, name: "Frank")
    visit url_prefix + "/partners/#{partner.id}/edit"
    fill_in "Name", with: "Franklin"
    click_button "Update Partner"

    expect(page.find(".alert")).to have_content "updated"
    partner.reload
    expect(partner.name).to eq("Franklin")
  end

  scenario "User updates a partner with empty name" do
    partner = create(:partner, name: "Frank")
    visit url_prefix + "/partners/#{partner.id}/edit"
    fill_in "Name", with: ""
    click_button "Update Partner"

    expect(page.find(".alert")).to have_content "didn't work"
  end
end
