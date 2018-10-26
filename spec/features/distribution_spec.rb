RSpec.feature "Distributions", type: :feature do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    @partner = create(:partner, organization: @organization)
    # allow_any_instance_of(StorageLocation).to receive(:geocode).and_return(true)
    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  scenario "User creates a new distribution" do
    visit @url_prefix + "/distributions/new"

    select @partner.name, from: "Partner"
    select @storage_location.name, from: "From storage location"

    fill_in "Comment", with: "Take my wipes... please"
    click_button "Save", match: :first
    expect(page).to have_content "Distributions"
    expect(page.find(".alert-info")).to have_content "reated"
  end

  scenario "User doesn't fill storage_location" do
    visit @url_prefix + "/distributions/new"

    select @partner.name, from: "Partner"
    select "", from: "From storage location"

    click_button "Save", match: :first
    expect(page).to have_content "An error occurred, try again?"
  end

  context "When creating a distribution from a donation" do
    let(:donation) { create :donation, :with_items }
    before do
      visit @url_prefix + "/donations/#{donation.id}"
      click_on "Start a new Distribution"
      within "#new_distribution" do
        select @partner.name, from: "Partner"
        click_button "Save"
      end
    end

    scenario "it completes successfully" do
      expect(page).to have_content "Distributions"
      expect(page.find(".alert-info")).to have_content "reated"
      expect(Distribution.first.line_items.count).to eq 1
    end

    context "when editing that distribution" do
      before do
        click_on "Edit", match: :first
        @distribution = Distribution.last
      end

      scenario "User creates a distribution from a donation then edits it" do
        within "#edit_distribution_#{@distribution.to_param}" do
          first(".numeric").set 13
          click_on "Save"
        end
        expect(page).to have_content "Distribution updated!"
        expect(page).to have_content 13
      end

      scenario "User creates a distribution from a donation then tries to make the quantity too big" do
        within "#edit_distribution_#{@distribution.to_param}" do
          first(".numeric").set 999_999
          click_on "Save"
        end
        expect(page).to have_no_content "Distribution updated!"
        expect(page).to have_content "Distribution could not be updated!"
        expect(page).to have_no_content 999_999
        expect(Distribution.first.line_items.count).to eq 1
      end
    end
  end

  context "When creating a distrubition from a request" do
    before do
      request_items = @storage_location.items.map(&:canonical_item).pluck(:partner_key).collect { |k| [k, rand(3..10)] }.to_h
      @request = create :request, organization: @organization, request_items: request_items

      visit @url_prefix + "/requests/#{@request.id}"
      click_on "Fulfill request"
      within "#new_distribution" do
        select @storage_location.name, from: "From storage location"
        click_on "Save"
      end

      @distribution = Distribution.last
    end

    scenario "it sets the distribution id on the request" do
      expect(@request.reload.distribution_id).to eq @distribution.id
    end
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
