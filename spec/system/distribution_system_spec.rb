RSpec.feature "Distributions", type: :system do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    @partner = create(:partner, organization: @organization)
    # allow_any_instance_of(StorageLocation).to receive(:geocode).and_return(true)
    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  context "When creating a new distribution manually" do
    it "Allows a distribution to be created" do
      with_features email_active: true do
        visit @url_prefix + "/distributions/new"

        select @partner.name, from: "Partner"
        select @storage_location.name, from: "From storage location"

        fill_in "Comment", with: "Take my wipes... please"

        expect do
          click_button "Save", match: :first
        end.to change { PartnerMailerJob.jobs.size }.by(1)

        expect(page).to have_content "Distributions"
        expect(page.find(".alert-info")).to have_content "reated"
      end
    end

    it "Displays a complete form after validation errors" do
      with_features email_active: true do
        visit @url_prefix + "/distributions/new"

        # verify line items appear on initial load
        expect(page).to have_selector "#distribution_line_items"

        select @partner.name, from: "Partner"
        expect do
          click_button "Save"
        end.not_to change { PartnerMailerJob.jobs.size }

        # verify line items appear on reload
        expect(page).to have_content "New Distribution"
        expect(page).to have_selector "#distribution_line_items"
      end
    end
  end

  it "Does not include inactive items in the line item fields" do
    visit @url_prefix + "/distributions/new"

    item = Item.alphabetized.first

    select @storage_location.name, from: "From storage location"
    expect(page).to have_content(item.name)
    select item.name, from: "distribution_line_items_attributes_0_item_id"

    item.update(active: false)

    page.refresh
    select @storage_location.name, from: "From storage location"
    expect(page).to have_no_content(item.name)
  end

  it "User doesn't fill storage_location" do
    visit @url_prefix + "/distributions/new"

    select @partner.name, from: "Partner"
    select "", from: "From storage location"

    click_button "Save", match: :first
    expect(page).to have_content "An error occurred, try again?"
  end

  context "With an existing distribution" do
    let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: @user.organization) }

    before do
      visit @url_prefix + "/distributions"
    end

    it "the user can make changes to it" do
      click_on "Edit", match: :first
      expect do
        fill_in "Agency representative", with: "SOMETHING DIFFERENT"
        click_on "Save", match: :first
        distribution.reload
      end.to change { distribution.agency_rep }.to("SOMETHING DIFFERENT")
    end

    it "the user can reclaim it" do
      expect do
        accept_confirm do
          click_on "Reclaim"
        end
        expect(page).to have_content "reclaimed"
      end.to change { Distribution.count }.by(-1)
    end

    context "when one of the items has been 'deleted'" do
      it "the user can still reclaim it and it reactivates the item", js: true do
        item = distribution.line_items.first.item
        item.destroy
        expect do
          accept_confirm do
            click_on "Reclaim"
          end
          page.find ".alert"
        end.to change { Distribution.count }.by(-1).and change { Item.active.count }.by(1)
        expect(page).to have_content "reclaimed"
      end
    end
  end

  context "When creating a distribution and items have value" do
    before do
      item1 = create(:item, value_in_cents: 1050)
      item2 = create(:item)
      item3 = create(:item, value_in_cents: 100)
      @distribution1 = create(:distribution, :with_items, item: item1, agency_rep: "A Person", organization: @user.organization)
      create(:distribution, :with_items, item: item2, agency_rep: "A Person", organization: @user.organization)
      @distribution3 = create(:distribution, :with_items, item: item3, agency_rep: "A Person", organization: @user.organization)
      visit @url_prefix + "/distributions"
    end

    it 'the user sees value in row on index page' do
      # row: 100 items * 1$
      expect(page).to have_content "$100"
    end

    it 'the user sees total value on index page' do
      # 100 items * 10.5 + 100 items * 1
      expect(page).to have_content "$1,150"
    end

    it 'the user sees value per item on show page' do
      # item value 10.50
      visit @url_prefix + "/distributions/#{@distribution1.id}"
      expect(page).to have_content "$10.50"
    end

    it 'the user sees total value on show page' do
      # 100 items * 10.5
      visit @url_prefix + "/distributions/#{@distribution1.id}"
      expect(page).to have_content "$1,050"
    end
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

    it "it completes successfully" do
      expect(page).to have_content "Distributions"
      expect(page.find(".alert-info")).to have_content "reated"
      expect(Distribution.first.line_items.count).to eq 1
    end

    context "when editing that distribution" do
      before do
        click_on "Edit", match: :first
        @distribution = Distribution.last
      end

      it "User creates a distribution from a donation then edits it" do
        within "#edit_distribution_#{@distribution.to_param}" do
          first(".numeric").set 13
          click_on "Save"
        end
        expect(page).to have_content "Distribution updated!"
        expect(page).to have_content 13
      end

      it "User creates a distribution from a donation then tries to make the quantity too big", js: true do
        within "#edit_distribution_#{@distribution.to_param}" do
          first(".numeric").set 999_999
          click_on "Save"
        end
        expect(page).to have_no_content "Distribution updated!"
        # NOTE: This is rendering the app/views/errors/insufficient.html.erb template
        expect(page).to have_content(/Insufficient/i)
        expect(page).to have_no_content 999_999
        expect(Distribution.first.line_items.count).to eq 1
      end

      it "User creates duplicate line items" do
        diaper_type = @distribution.line_items.first.item.name
        first_item_name_field = 'distribution_line_items_attributes_0_item_id'
        select(diaper_type, from: first_item_name_field)
        find_all(".numeric")[0].set 1

        click_on "Add another item"
        second_item_name_field = 'distribution_line_items_attributes_1_item_id'
        select(diaper_type, from: second_item_name_field)
        find_all(".numeric")[1].set 3
        first(".btn", text: "Save").click

        expect(page).to have_css "td"
        item_row = find("td", text: diaper_type).find(:xpath, '..')
        expect(item_row).to have_content("#{diaper_type} 4")
      end
    end
  end

  # TODO: This should probably be in the Request resource specs, not Distribution
  context "When creating a distrubition from a request" do
    before do
      items = @storage_location.items.pluck(:id).sample(2)
      request_items = [{ "item_id" => items[0], "quantity" => 10 }, { "item_id" => items[1], "quantity" => 10 }]
      @request = create :request, organization: @organization, request_items: request_items

      visit @url_prefix + "/requests/#{@request.id}"
      click_on "Fulfill request"
      within "#new_distribution" do
        select @storage_location.name, from: "From storage location"
        click_on "Save"
      end

      @distribution = Distribution.last
    end

    it "it sets the distribution id and fulfilled status on the request" do
      expect(@request.reload.distribution_id).to eq @distribution.id
      expect(@request.reload).to be_status_fulfilled
    end
  end

  context "via barcode entry" do
    before(:each) do
      initialize_barcodes
      visit @url_prefix + "/distributions/new"
    end

    it "a user can add items via scanning them in by barcode", js: true do
      Barcode.boop(@existing_barcode.value)
      # the form should update
      qty = page.find(:xpath, '//input[@id="distribution_line_items_attributes_0_quantity"]').value

      expect(qty).to eq(@existing_barcode.quantity.to_s)
    end

    it "a user can add items that do not yet have a barcode" do
      # enter a new barcode
      # page.fill_in "_barcode-lookup-0", with: "123123123321\n"
      # find('#_barcode-lookup-0').set("123123123321\n")
      #
      # page.fill_in "Quantity", with: "50"
      # select "Adult Briefs (Large/X-Large)", from: "Item"
      # page.fill_in "Barcode", with: "123123123321"
      #
      # find("#awesomebutton").click
      #
      # visit @url_prefix + "/distributions/new"
      # page.fill_in "_barcode-lookup-0", with: "123123123321\n"
      #
      # expect(page).to have_text("50")
    end
  end

  context "when filtering on the index page" do
    let(:item1)    { create(:item, name: "Good item") }
    let(:item2)    { create(:item, name: "Crap item") }
    let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com") }
    let(:partner2) { create(:partner, name: "Not This Guy", email: "ntg@example.com") }

    it "filters by item id" do
      create(:distribution, :with_items, item: item1)
      create(:distribution, :with_items, item: item2)

      visit @url_prefix + "/distributions"
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 3)
      # filter
      select(item1.name, from: "filters_by_item_id")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 2)
    end

    it "filters by partner" do
      create(:distribution, partner: partner1)
      create(:distribution, partner: partner2)

      visit @url_prefix + "/distributions"
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 3)
      # filter
      select(partner1.name, from: "filters_by_partner")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 2)
    end

    it "Filters by date" do
      create(:distribution, issued_at: Time.zone.today)
      create(:distribution, issued_at: Time.zone.today)
      create(:distribution, issued_at: Time.zone.today + 2.weeks)
      visit @url_prefix + "/distributions"

      expect(page).to have_css("table tbody tr", count: 4)
      select("This Week", from: "filters_interval")
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)
    end
  end
end
