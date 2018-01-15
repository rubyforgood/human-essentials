RSpec.feature "Dropoff location", type: :feature do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }

  context "When a user views the index page" do
    before(:each) do
      @second = create(:dropoff_location, name: "Bcd")
      @first = create(:dropoff_location, name: "Abc")
      @third = create(:dropoff_location, name: "Cde")
      visit url_prefix + '/dropoff_locations'
    end
    scenario "the dropoff locations are in alphabetical order" do
      expect(page).to have_xpath("//table/tr", count: 4)
      expect(page.find(:xpath, "//table/tr[2]/td[1]")).to have_content(@first.name)
      expect(page.find(:xpath, "//table/tr[4]/td[1]")).to have_content(@third.name)
    end
  end

  scenario "User creates a new dropoff location" do
    visit url_prefix + '/dropoff_locations/new'
    dropoff_location_traits = attributes_for(:dropoff_location)
    fill_in "Name", with: dropoff_location_traits[:name]
    fill_in "Address", with: dropoff_location_traits[:address]
    click_button "Create Dropoff location"

    expect(page.find('.alert')).to have_content "added"
  end

  scenario "User updates an existing dropoff location" do
    dropoff_location = create(:dropoff_location)
    visit url_prefix + "/dropoff_locations/#{dropoff_location.id}/edit"
    fill_in "Address", with: dropoff_location.name + " new"
    click_button "Update Dropoff location"

    expect(page.find('.alert')).to have_content "updated"
  end

end
