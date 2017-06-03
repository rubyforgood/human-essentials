RSpec.feature "Dashboard", type: :feature do
  before :each do
    sign_in(@user)
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting a new dashboard" do
    before(:each) do
      visit @url_prefix + "/dashboard"
    end

    scenario "User should see their organization name" do
      expect(page.find('.organization-name')).to have_content(@organization.name)
    end

  end

  # TODO - For right now, I'm eschewing the JS interaction because XHRs are annoying to do with capybara
  # if someone else wants to make this use an XHR instead, have at it!
  scenario "The user can scope down what they see in the dashboard using the date-range drop down" do
    item = create(:item, organization: @organization)
    create(:storage_location, organization: @organization)
    create(:donation, :with_item, item_id: item.id, item_quantity: 10, issued_at: 1.month.ago)
    create(:donation, :with_item, item_id: item.id, item_quantity: 200, issued_at: Date.today)
    @organization.reload

    # Verify the initial totals are correct
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("210 items received year to date")

    # Scope it down to just today, should omit the first donation
    #select "Yesterday", from: "dashboard_filter_interval" # LET'S PRETEND BECAUSE OF REASONS!
    visit @url_prefix + "/dashboard?dashboard_filter[interval]=last_month"
    expect(page).to have_content("10 items received last month")
  end


  scenario "inventory totals on dashboard are updated immediately after donations and distributions are made", js:true do
    create(:partner)
    create(:item, organization: @organization)
    create(:storage_location, organization: @organization)
    create(:dropoff_location, organization: @organization)
    create(:diaper_drive_participant, organization: @organization)
    @organization.reload

    # Verify the initial totals on dashboard
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("0 items received")
    expect(page).to have_content("0 items on-hand")

    # Make a donation
    visit @url_prefix + "/donations/new"
    select "Misc. Donation", from: "donation_source"
    expect(page).not_to have_xpath("//select[@id='donation_dropoff_location_id']")
    expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
    select StorageLocation.first.name, from: "donation_storage_location_id"
    select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
    fill_in "donation_line_items_attributes_0_quantity", with: "100"
    click_button "Create Donation"

    # Check the dashboard now
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("100 items received")
    expect(page).to have_content("100 items on-hand")

    # Check distributions
    visit @url_prefix + "/distributions/new"
    select Partner.last.name, from: "distribution_partner_id"
    select @organization.storage_locations.first.name, from: "distribution_storage_location_id"
    select Item.last.name, from: "distribution_line_items_attributes_0_item_id"
    fill_in "distribution_line_items_attributes_0_quantity", with: "50"
    click_button "Create Distribution"
    expect(page).to have_xpath("//table[@id='distributions']/tbody/tr/td", text: "50")      

    # Check the dashboard now
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("100 items received")
    expect(page).to have_content("50 items distributed")
    expect(page).to have_content("50 items on-hand")
  end
end
