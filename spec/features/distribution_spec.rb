RSpec.feature "Distributions", type: :feature do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    @partner = create(:partner, organization: @organization)
    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  scenario "User creates a new distribution" do
    pending "FIXME: distributions require line items. see comments for error messages"
    # Line items item must exist,
    # Line items item can't be blank,
    # Line items quantity can't be blank,
    # Line items is invalid
    visit @url_prefix + "/distributions/new"

    select @partner.name, from: "Partner"
    select @storage_location.name, from: "From storage location"

    fill_in "Comment", with: "Take my wipes... please"
    click_button "Create Distribution"

    expect(page.find('.flash.success')).to have_content "ompleted"
  end
end
