RSpec.feature "Distributions", type: :feature do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    @partner = create(:partner, organization: @organization)
    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  scenario "User creates a new distribution" do
    visit @url_prefix + "/distributions/new"

    select @partner.name, from: "Partner"
    select @storage_location.name, from: "From storage location"

    fill_in "Comment", with: "Take my wipes... please"
    click_button "Preview Distribution"
    expect(page).to have_content "Distribution Manifest for"
    click_button "Confirm Distribution"
    expect(page.find('.alert-info')).to have_content "reated"
  end

  scenario "User can create a distribution from donation" do
    @donation = create :donation, :with_items

    visit @url_prefix + "/donations/#{@donation.id}"
    click_on "Create distribution"
    select @partner.name, from: "Partner"
    click_button "Preview Distribution"
    expect(page).to have_content "Distribution Manifest for"
    click_button "Confirm Distribution"
    expect(page.find('.alert-info')).to have_content "reated"
    expect(Distribution.first.line_items.count).to eq 1
  end

  context "via barcode entry" do
    before(:each) do
      initialize_barcodes
      visit @url_prefix + "/distributions/new"
    end

    scenario "a user can add items via scanning them in by barcode", js: true do
      pending "The JS doesn't appear to be executing in this correctly"
      # I tried (3 Feb) to get this working and it still doesn't execute.
      # The data gets put into the field correctly, tho it doesn't show up on
      # the browser snapshot -- but the Ajax doesn't execute. Not sure why this is broken.
      # enter the barcode into the barcode field
      page.fill_in "_barcode-lookup-0", with: @existing_barcode.value + 13.chr
      # the form should update
      qty = page.find(:xpath, '//input[@id="distribution_line_items_attributes_0_quantity"]').value
#save_and_open_page

      expect(qty).to eq(@existing_barcode.quantity.to_s)
    end

    scenario "a user can add items that do not yet have a barcode" do
      # enter a new barcode
      # form finds no barcode and responds by prompting user to choose an item and quantity
      # fill that in
      # saves new barcode
      # form updates
      pending "TODO: adding items with a new barcode"
      raise
    end

  end

  context "When editing a distribution" do
    fscenario "User removes an item" do
      # user removes a line item
      # response should be successful
      # storage location should be bigger

      distribution = create(:distribution)
      visit @url_prefix + "/distributions/#{distribution.id}/edit"
      page.first(:css, ".remove_fields").click
      click_button "Update Distribution"
      expect(page.find('.alert-info')).to have_content "pdated"
    end

    fscenario "User changes storage location" do
      # user changes storage location
      # response should be successful
      # storage location A should be bigger
      # storage location B should be smaller

      item = create(:item)
      storage_location_a = create(:storage_location, :with_items, item: item, item_quantity: 100, name: 'Location A')
      storage_location_b = create(:storage_location, :with_items, item: item, item_quantity: 100, name: 'Location B')

      distribution = create(:distribution, :with_items, item: item, item_quantity: 10, storage_location: storage_location_a)
      visit @url_prefix + "/distributions/#{distribution.id}/edit"

      # change storage location
      # remove line item
      # submit
      # should be successful

      select storage_location_b.name, from: "From storage location"
      click_button "Update Distribution"
      expect(page.find('.alert-info')).to have_content "pdated"
      expect(storage_location_a.size).to be > storage_location_b.size
    end

    xscenario "User changes storage location but new storage location has insufficient inventory" do
      # user changes storage location
      # response should not be successful
      # storage location A should be unchanged
      # storage location B should be unchanged
    end

    scenario "User changes item and storage location" do
      first_storage_location = StorageLocation.first
      distribution = create(:distribution, storage_location: first_storage_location)
      visit @url_prefix + "/distributions/#{distribution.id}/edit"

      # change storage location
      # remove line item
      # submit
      # should be successful

      last_storage_location = StorageLocation.last
      select last_storage_location.name, from: "From storage location"
      page.first(:css, ".remove_fields").click
      click_button "Update Distribution"
      expect(page.find('.alert-info')).to have_content "pdated"
      expect(last_storage_location)
    end

    scenario "User changes item and storage location and new storage location has insufficient inventory" do
      first_storage_location = StorageLocation.first
      distribution = create(:distribution, storage_location: first_storage_location)
      visit @url_prefix + "/distributions/#{distribution.id}/edit"

      # change storage location
      # remove line item
      # submit
      # should be successful

      last_storage_location = StorageLocation.last
      select last_storage_location.name, from: "From storage location"
      page.first(:css, ".remove_fields").click
      click_button "Update Distribution"
      expect(page.find('.alert-info')).to have_content "pdated"
      expect(last_storage_location)
    end
  end
end
