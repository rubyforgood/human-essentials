RSpec.feature "Dropoff location", type: :feature do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new dropoff location" do
    visit url_prefix + '/dropoff_locations/new'
    dropoff_location_traits = attributes_for(:dropoff_location)
    fill_in "Name", with: dropoff_location_traits[:name]
    fill_in "Address", with: dropoff_location_traits[:address]
    click_button "Create Dropoff location"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User updates an existing dropoff location" do
    dropoff_location = create(:dropoff_location)
    visit url_prefix + "/dropoff_locations/#{dropoff_location.id}/edit"
    fill_in "Address", with: dropoff_location.name + " new"
    click_button "Update Dropoff location"

    expect(page.find('.flash.success')).to have_content "updated"
  end

end
