RSpec.feature "Distributions", type: :feature do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    create(:partner)
    @storage_location = create(:storage_location)
    setup_storage_location(@storage_location)
  end

  scenario "User creates a new distribution" do
    pending "TODO - This spec. Or else."
  	visit @url_prefix + "/distributions/new"
  	select Partner.first, from: "distribution[partner_id]"
  	select StorageLocation.first, from: "distribution[storage_location_id]"
  	fill_in "Comment", with: "Take my wipes... please"
  	click_button "Create Distribution"
  	save_and_open_page
  	#expect(page.find('.flash.success')).to have_content "ompleted"
  end
end