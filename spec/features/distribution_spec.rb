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
    expect(page.find(".alert-info")).to have_content "reated"
  end

  scenario "User can create a distribution from donation" do
    @donation = create :donation, :with_items

    visit @url_prefix + "/donations/#{@donation.id}"
    click_on "Create distribution"
    select @partner.name, from: "Partner"
    click_button "Preview Distribution"
    expect(page).to have_content "Distribution Manifest for"
    click_button "Confirm Distribution"
    expect(page.find(".alert-info")).to have_content "reated"
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
      # save_and_open_page

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
end
