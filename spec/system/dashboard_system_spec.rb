RSpec.describe "Dashboard", type: :system, js: true do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.short_name}" }
  subject { url_prefix + "/dashboard" }

  context "When visiting a new dashboard" do
    before(:each) do
      visit subject
    end

    it "should show the User their organization name unless they have a logo set" do
      # extract just the filename
      header_logo = extract_image(:xpath, "//img[@id='logo']")
      expect(header_logo).to be_include("diaper-base-logo")

      organization_logo = extract_image(:xpath, "//div/img")
      expect(organization_logo).to eq("logo.jpg")

      @organization.logo.purge
      @organization.save
      visit subject

      expect(page).not_to have_xpath("//div/img")
      expect(page.find(:xpath, "//div[@class='logo']")).to have_content(@organization.name)
    end
  end

  it "should scope down what the user sees in the dashboard using the date-range drop down" do
    Timecop.freeze(Time.utc(2018, 6, 15, 12, 0, 0)) do
      item = create(:item, organization: @organization)
      sl = create(:storage_location, :with_items, item: item, item_quantity: 125, organization: @organization)
      create(:donation, :with_items, item: item, item_quantity: 10, storage_location: sl, issued_at: 1.month.ago)
      create(:donation, :with_items, item: item, item_quantity: 200, storage_location: sl, issued_at: Time.zone.today)
      create(:distribution, :with_items, item: item, item_quantity: 5, storage_location: sl, issued_at: 1.month.ago,)
      create(:distribution, :with_items, item: item, item_quantity: 100, storage_location: sl, issued_at: Time.zone.today,)

      m_a = create(:manufacturer)
      m_b = create(:manufacturer)
      create(:donation, :with_items, item: item, item_quantity: 25, source: Donation::SOURCES[:manufacturer], manufacturer: m_a, issued_at: 1.month.ago)
      create(:donation, :with_items, item: item, item_quantity: 75, source: Donation::SOURCES[:manufacturer], manufacturer: m_b, issued_at: Time.zone.today)

      # Verify the initial totals are correct
      visit url_prefix + "/dashboard"
      expect(page).to have_content("310 items received year to date")
      expect(page).to have_content("105 items distributed year to date")
      expect(page).to have_content("0 Diaper Drives")
      expect(page).to have_content("100 items donated year to date by 2 Manufacturers")

      # Scope it down to just today, should omit the first donation
      # select "Yesterday", from: "dashboard_filter_interval" # LET'S PRETEND BECAUSE OF REASONS!
      visit url_prefix + "/dashboard?dashboard_filter[interval]=last_month"
      expect(page).to have_content("35 items received last month")
      expect(page).to have_content("5 items distributed last month")
      expect(page).to have_content("25 items donated last month by 1 Manufacturer")
    end
  end

  context "inventory" do
    let(:donation) { create(:donation, :with_items, organization: @organization) }
    let(:purchase) { create(:purchase, :with_items, organization: @organization) }
    let(:distribution) { create(:distribution, :with_items, organization: @organization) }

    before do
      create(:partner)
      create(:item, organization: @organization)
      create(:storage_location, organization: @organization)
      create(:donation_site, organization: @organization)
      create(:diaper_drive_participant, organization: @organization)
      create(:manufacturer, organization: @organization)
      @organization.reload
    end

    context "inactive item" do
      it 'should not count totals for donations' do
        item = donation.storage_location.items.first
        visit subject
        expect(page).to have_content("100 items received year to date")

        item.update(active: false)
        visit subject
        expect(page).to_not have_content("100 items received year to date")
      end

      it 'should not count totals for purchases' do
        item = purchase.storage_location.items.first
        visit subject
        expect(page).to have_content("100 items received year to date")

        item.update(active: false)
        visit subject
        expect(page).to_not have_content("100 items received year to date")
      end

      it 'should not count totals for distributions' do
        item = distribution.storage_location.items.first
        visit subject
        expect(page).to have_content("100 items distributed year to date")

        item.update(active: false)
        visit subject
        expect(page).to_not have_content("100 items distributed year to date")
      end
    end

    it "should update totals on dashboard immediately after donations and distributions are made", js: true do
      # Verify the initial totals on dashboard
      visit subject
      expect(page).to have_content("0 items received")
      expect(page).to have_content("0 items on-hand")

      # Make a donation
      visit url_prefix + "/donations/new"
      select "Misc. Donation", from: "donation_source"
      expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
      expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
      expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
      select StorageLocation.first.name, from: "donation_storage_location_id"
      select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
      fill_in "donation_line_items_attributes_0_quantity", with: "100"
      click_button "Save"

      # Make a diaper drive donation
      visit url_prefix + "/donations/new"
      select "Diaper Drive", from: "donation_source"
      select DiaperDriveParticipant.first.business_name, from: "donation_diaper_drive_participant_id"
      select StorageLocation.first.name, from: "donation_storage_location_id"
      select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
      fill_in "donation_line_items_attributes_0_quantity", with: "100"
      click_button "Save"

      # Make a manufacturer donation
      visit url_prefix + "/donations/new"
      select "Manufacturer", from: "donation_source"
      select Manufacturer.first.name, from: "donation_manufacturer_id"
      select StorageLocation.first.name, from: "donation_storage_location_id"
      select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
      fill_in "donation_line_items_attributes_0_quantity", with: "75"
      click_button "Save"

      # Check the dashboard now
      visit url_prefix + "/dashboard"
      expect(page).to have_content("275 items received")
      expect(page).to have_content("275 items on-hand")
      expect(page).to have_content("75 items donated year to date by 1 Manufacturer")

      # Check distributions
      visit url_prefix + "/distributions/new"
      select Partner.last.name, from: "distribution_partner_id"
      select @organization.storage_locations.first.name, from: "distribution_storage_location_id"
      select Item.last.name, from: "distribution_line_items_attributes_0_item_id"
      fill_in "distribution_line_items_attributes_0_quantity", with: "50"
      click_button "Save"
      click_on "View", match: :first
      expect(page).to have_content "Distribution Manifest for"
      expect(page).to have_xpath("//table/tbody/tr/td", text: "50")

      # Check the dashboard now
      visit url_prefix + "/dashboard"
      expect(page).to have_content("275 items received")
      expect(page).to have_content("50 items distributed")
      expect(page).to have_content("225 items on-hand")
      expect(page).to have_content("1 Diaper Drives")
    end

    it "should list top 10 manufacturers" do
      visit url_prefix + "/dashboard"
      expect(page).to have_content("0 items donated year to date by 0 Manufacturers")

      item_qty = 200
      12.times do
        manufacturer = create(:manufacturer)
        create(:donation, :with_items, item: Item.first, item_quantity: item_qty, source: Donation::SOURCES[:manufacturer], manufacturer: manufacturer, issued_at: Time.zone.today)
        item_qty -= 1
      end

      visit url_prefix + "/dashboard"
      expect(page).to have_content("2,334 items donated year to date by 12 Manufacturers")
      expect(page).to have_content "Top Manufacturer Donations"
      expect(page).to have_css(".manufacturer", count: 10)
    end
  end

  it "displays the getting started guide as expected", js: true do
    # When dashboard loads, ensure that we are on step 1 (Partner Agencies)
    Partner.delete_all
    visit subject
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

    # After we create a partner, ensure that we are on step 2 (Storage Locations)
    @partner = create(:partner, organization: @organization)
    visit subject
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

    # After we create a storage location, ensure that we are on step 3 (Donation Site)
    create(:storage_location, organization: @organization)
    visit subject
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

    # After we create a donation site, ensure that we are on step 4 (Inventory)
    create(:donation_site, organization: @organization)
    visit subject
    expect(page).to have_selector("#getting-started-guide", count: 1)
    expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
    expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 1)

    # After we add inventory to a storage location, ensure that the getting starting guide is gone
    create(:storage_location, :with_items, item_quantity: 125, organization: @organization)
    visit subject
    expect(page).to have_selector("#getting-started-guide", count: 0)
  end
end