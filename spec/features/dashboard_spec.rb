RSpec.feature "Dashboard", type: :feature do
  before :each do
    sign_in(@user)
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting a new dashboard" do
    before(:each) do
      visit @url_prefix + "/dashboard"
    end

    scenario "User should see their organization name unless they have a logo set" do
      # extract just the filename
      header_logo = extract_image(:xpath, "//img[@id='logo']")
      expect(header_logo).to be_include("DiaperBase-Logo")

      organization_logo = extract_image(:xpath, "//div/img")
      expect(organization_logo).to eq("logo.jpg")

      @organization.logo.purge
      @organization.save
      visit @url_prefix + "/dashboard"

      expect(page).not_to have_xpath("//div/img")
      expect(page.find(:xpath, "//div[@class='logo']")).to have_content(@organization.name)
    end
  end

  scenario "The user can scope down what they see in the dashboard using the date-range drop down" do
    item = create(:item, organization: @organization)
    sl = create(:storage_location, :with_items, item: item, item_quantity: 125, organization: @organization)
    create(:donation, :with_items, item: item, item_quantity: 10, storage_location: sl, issued_at: 1.month.ago)
    create(:donation, :with_items, item: item, item_quantity: 200, storage_location: sl, issued_at: Date.today)
    create(:distribution, :with_items, item: item, item_quantity: 5, storage_location: sl, issued_at: 1.month.ago,)
    create(:distribution, :with_items, item: item, item_quantity: 100, storage_location: sl, issued_at: Date.today,)
    @organization.reload

    # Verify the initial totals are correct
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("210 items received year to date")
    expect(page).to have_content("105 items distributed year to date")
    expect(page).to have_content("0 Diaper Drives")

    # Scope it down to just today, should omit the first donation
    # select "Yesterday", from: "dashboard_filter_interval" # LET'S PRETEND BECAUSE OF REASONS!
    visit @url_prefix + "/dashboard?dashboard_filter[interval]=last_month"
    expect(page).to have_content("10 items received last month")
    expect(page).to have_content("5 items distributed last month")
  end

  scenario "inventory totals on dashboard are updated immediately after donations and distributions are made", js: true do
    create(:partner)
    create(:item, organization: @organization)
    create(:storage_location, organization: @organization)
    create(:donation_site, organization: @organization)
    create(:diaper_drive_participant, organization: @organization)
    @organization.reload

    # Verify the initial totals on dashboard
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("0 items received")
    expect(page).to have_content("0 items on-hand")

    # Make a donation
    visit @url_prefix + "/donations/new"
    select "Misc. Donation", from: "donation_source"
    expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
    expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
    select StorageLocation.first.name, from: "donation_storage_location_id"
    select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
    fill_in "donation_line_items_attributes_0_quantity", with: "100"
    click_button "Create Donation"

    # Make a diaper drive donation
    visit @url_prefix + "/donations/new"
    select "Diaper Drive", from: "donation_source"
    select DiaperDriveParticipant.first.name, from: "donation_diaper_drive_participant_id"
    select StorageLocation.first.name, from: "donation_storage_location_id"
    select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
    fill_in "donation_line_items_attributes_0_quantity", with: "100"
    click_button "Create Donation"

    # Check the dashboard now
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("200 items received")
    expect(page).to have_content("200 items on-hand")

    # Check distributions
    visit @url_prefix + "/distributions/new"
    select Partner.last.name, from: "distribution_partner_id"
    select @organization.storage_locations.first.name, from: "distribution_storage_location_id"
    select Item.last.name, from: "distribution_line_items_attributes_0_item_id"
    fill_in "distribution_line_items_attributes_0_quantity", with: "50"
    click_button "Preview Distribution"
    expect(page).to have_content "Distribution Manifest for"
    click_button "Confirm Distribution"
    expect(page).to have_xpath("//table/tbody/tr/td", text: "50")

    # Check the dashboard now
    visit @url_prefix + "/dashboard"
    expect(page).to have_content("200 items received")
    expect(page).to have_content("50 items distributed")
    expect(page).to have_content("150 items on-hand")
    expect(page).to have_content("1 Diaper Drives")
  end

  scenario "getting started guide works as expected", js: true do
    # When dashboard loads, ensure that we are on step 1 (Partner Agencies)
    visit @url_prefix + "/dashboard"
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

    # After we create a partner, ensure that we are on step 2 (Storage Locations)
    create(:partner)
    visit @url_prefix + "/dashboard"
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

    # After we create a storage location, ensure that we are on step 3 (Donation Site)
    create(:storage_location, organization: @organization)
    visit @url_prefix + "/dashboard"
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

    # After we create a donation site, ensure that we are on step 4 (Inventory)
    create(:donation_site, organization: @organization)
    visit @url_prefix + "/dashboard"
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 1)

    # After we add inventory to a storage location, ensure that the getting starting guide is gone
    item = create(:item, organization: @organization)
    create(:storage_location, :with_items, item: item, item_quantity: 125, organization: @organization)
    visit @url_prefix + "/dashboard"
    expect(page).to have_selector("#getting-started-guide", count: 0)
  end
end
