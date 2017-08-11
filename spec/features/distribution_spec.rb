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

  context "via barcode entry" do
    before(:each) do
      initialize_barcodes
      visit @url_prefix + "/distributions/new"
    end

    scenario "a user can add items via scanning them in by barcode" do
      pending "The JS doesn't appear to be executing in this correctly"
      # enter the barcode into the barcode field
      fill_in "_barcode-lookup-0", with: @existing_barcode.value
      # the form should update
      qty = page.find(:xpath, '//input[@id="donation_line_items_attributes_0_quantity"]').value

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
