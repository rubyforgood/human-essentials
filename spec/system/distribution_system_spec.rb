RSpec.feature "Distributions", type: :system do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    @partner = create(:partner, organization: @organization)

    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  context "When going to the Pick Ups & Deliveries page" do
    let(:issued_at) { Time.current.utc.change(hour: 19, minute: 0).to_datetime }
    before do
      item1 = create(:item, value_in_cents: 1050)
      @distribution = create(:distribution, :with_items, item: item1, agency_rep: "A Person", organization: @user.organization, issued_at: issued_at)
    end

    it "appears distribution in calendar with correct time & timezone" do
      visit @url_prefix + "/distributions/schedule"
      expect(page.find(".fc-event-time")).to have_content "7p"
      expect(page.find(".fc-event-title")).to have_content @distribution.partner.name
    end
  end

  context "When creating a new distribution manually" do
    it "Allows a distribution to be created" do
      visit @url_prefix + "/distributions/new"

      select @partner.name, from: "Partner"
      select @storage_location.name, from: "From storage location"
      choose "Pick up"

      fill_in "Comment", with: "Take my wipes... please"
      fill_in "Distribution date", with: '01/01/2001 10:15:00 AM'

      expect(PartnerMailerJob).to receive(:perform_later).once
      click_button "Save", match: :first

      expect(page).to have_content "Distributions"
      expect(page.find(".alert-info")).to have_content "reated"
    end

    it "Displays a complete form after validation errors" do
      visit @url_prefix + "/distributions/new"

      # verify line items appear on initial load
      expect(page).to have_selector "#distribution_line_items"

      select @partner.name, from: "Partner"
      expect do
        click_button "Save"
      end.not_to change { ActionMailer::Base.deliveries.count }

      # verify line items appear on reload
      expect(page).to have_content "New Distribution"
      expect(page).to have_selector "#distribution_line_items"
    end

    context "when the quantity is lower than the on hand minimum quantity" do
      it "should display an error" do
        visit @url_prefix + "/distributions/new"
        item = @storage_location.inventory_items.first.item
        item.update!(on_hand_minimum_quantity: 5)
        @storage_location.inventory_items.first.update!(quantity: 20)

        select @partner.name, from: "Partner"
        select @storage_location.name, from: "From storage location"
        select item.name, from: "distribution_line_items_attributes_0_item_id"
        select @storage_location.name, from: "distribution_storage_location_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: 18

        click_button "Save"

        expect(page).not_to have_content('New Distribution')
        expect(page).to have_content("The following items have fallen below the minimum on hand quantity: #{item.name}")
      end
    end

    context "when the quantity is lower than the on hand recommended quantity" do
      it "should display an alert" do
        visit @url_prefix + "/distributions/new"
        item = @storage_location.inventory_items.first.item
        item.update!(on_hand_minimum_quantity: 1, on_hand_recommended_quantity: 5)
        @storage_location.inventory_items.first.update!(quantity: 20)

        select @partner.name, from: "Partner"
        select @storage_location.name, from: "From storage location"
        select item.name, from: "distribution_line_items_attributes_0_item_id"
        select @storage_location.name, from: "distribution_storage_location_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: 18

        click_button "Save"

        expect(page).to have_content("The following items have fallen below the recommended on hand quantity: #{item.name}")
      end
    end

    context "when there is insufficient inventory to fulfill the Distribution" do
      it "gracefully handles the error" do
        visit @url_prefix + "/distributions/new"

        select @partner.name, from: "Partner"
        select @storage_location.name, from: "From storage location"
        choose "Delivery"

        fill_in "Comment", with: "Take my wipes... please"

        item = @storage_location.inventory_items.first.item
        quantity = @storage_location.inventory_items.first.quantity
        select item.name, from: "distribution_line_items_attributes_0_item_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: quantity * 2

        expect do
          click_button "Save", match: :first
          page.find('.alert')
        end.not_to change { Distribution.count }

        expect(page).to have_content("New Distribution")
        expect(page.find(".alert")).to have_content "exceed"
      end
    end
    context "when there is a default storage location" do
      it "automatically selects the default storage location" do
        @organization.default_storage_location = @storage_location.id
        visit @url_prefix + "/distributions/new"
        expect(find("#distribution_storage_location_id").text).to eq(@storage_location.name)
      end
    end
    it "should not display inactive storage locations in dropdown" do
      inactive_location = create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
      setup_storage_location(inactive_location)
      visit @url_prefix + "/distributions/new"
      expect(page).to have_no_content "Inactive R Us"
    end
  end

  it "errors if user does not fill storage_location" do
    visit @url_prefix + "/distributions/new"

    select @partner.name, from: "Partner"
    select "", from: "From storage location"

    click_button "Save", match: :first
    page.find('.alert')
    expect(page).to have_css('.alert.error', text: /storage location/i)
  end

  context "With an existing distribution" do
    let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: @user.organization) }

    before do
      sign_in(@organization_admin)
      visit @url_prefix + "/distributions"
    end

    it "the user can make changes" do
      click_on "Edit", match: :first
      expect do
        fill_in "Agency representative", with: "SOMETHING DIFFERENT"
        click_on "Save", match: :first
        distribution.reload
      end.to change { distribution.agency_rep }.to("SOMETHING DIFFERENT")
    end

    it "sends an email if reminders are enabled" do
      job = double('fake_job')
      allow(DistributionMailer).to receive(:reminder_email).and_return(job)
      allow(job).to receive(:deliver_later)

      visit @url_prefix + "/distributions"
      click_on "Edit", match: :first
      fill_in "Agency representative", with: "SOMETHING DIFFERENT"
      click_on "Save", match: :first
      distribution.reload
      expect(job).to have_received(:deliver_later)
    end

    it "allows the user can change the issued_at date" do
      click_on "Edit", match: :first
      expect do
        fill_in "Distribution date", with: Time.zone.parse("2001-10-01 10:00")

        click_on "Save", match: :first
        distribution.reload
      end.to change { distribution.issued_at }.to(Time.zone.parse("2001-10-01 10:00"))
    end

    it "disallows the user from changing the quantity above the inventory quantity" do
      click_on "Edit", match: :first
      expect do
        fill_in 'distribution_line_items_attributes_0_quantity', with: distribution.line_items.first.quantity + 300
        click_on "Save", match: :first
      end.not_to change { distribution.line_items.first.quantity }
      within ".alert" do
        expect(page).to have_content "items exceed the available inventory"
      end
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

  context "When attempting to edit a distribution" do
    context "after the distribution issued_at has passed or it has been marked complete" do
      let!(:past_distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: @user.organization, issued_at: Time.zone.yesterday, state: :scheduled) }
      let!(:complete_distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: @user.organization, issued_at: Time.zone.today, state: :complete) }

      it "does not contain a Edit button" do
        visit @url_prefix + "/distributions"
        expect(page).not_to have_button("Edit")
      end

      it "cannot be accessed directly" do
        visit @url_prefix + "/distributions/#{past_distribution.id}/edit"
        expect(page.find(".alert-danger")).to have_content "you must be an organization admin"
        visit @url_prefix + "/distributions/#{complete_distribution.id}/edit"
        expect(page.find(".alert-danger")).to have_content "you must be an organization admin"
      end
    end

    context "when logged as Admin" do
      let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: @user.organization, issued_at: Time.zone.today.prev_day, state: :complete) }

      before do
        sign_in(@organization_admin)
      end

      it "can click on Edit button and a warning appears " do
        visit @url_prefix + "/distributions"
        click_on "Edit", match: :first
        expect(page.find(".alert-warning")).to have_content "The current date is past the date this distribution was scheduled for."
      end

      it "can be accessed directly" do
        visit @url_prefix + "/distributions/#{distribution.id}/edit"
        expect(page).to have_no_css(".alert-danger")
        expect(page.find(".alert-warning")).to have_content "The current date is past the date this distribution was scheduled for."
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

  context "When showing a individual distribution" do
    let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: @user.organization, issued_at: Time.zone.today, state: :complete) }

    before { visit @url_prefix + "/distributions/#{distribution.id}" }

    it "Show partner name in title" do
      expect(page).to have_content("Distribution from #{distribution.storage_location.name} to #{distribution.partner.name}")
    end
  end

  context "When creating a distribution from a donation" do
    let(:donation) { create :donation, :with_items }
    before do
      visit @url_prefix + "/donations/#{donation.id}"
      sign_in(@organization_admin)
      click_on "Start a new Distribution"
      within "#new_distribution" do
        select @partner.name, from: "Partner"
        choose "Pick up"
        click_button "Save"
      end
    end

    it "completes successfully" do
      expect(page).to have_content "Distributions"
      expect(page.find(".alert-info")).to have_content "reated"
      expect(Distribution.first.line_items.count).to eq 1
    end

    context "when editing that distribution" do
      before do
        click_on "Distributions", match: :first
        click_on "Edit", match: :first
        @distribution = Distribution.last
      end

      it "User creates a distribution from a donation then edits it" do
        within ".distribution_line_items_quantity" do
          first(".numeric").set 13
        end
        click_on "Save"
        expect(page).to have_content "Distribution updated!"
        expect(page).to have_content 13
      end

      it "User creates a distribution from a donation then tries to make the quantity too big", js: true do
        within ".distribution_line_items_quantity" do
          first(".numeric").set 999_999
        end
        click_on "Save"
        expect(page).to have_no_content "Distribution updated!"
        expect(page).to have_content(/items exceed the available inventory/i)
        expect(page).to have_content 999_999, count: 1
        within ".alert" do
          expect(page).to have_content 999_999
        end
        expect(Distribution.first.line_items.count).to eq 1
      end

      it "User creates duplicate line items" do
        item_type = @distribution.line_items.first.item.name
        first_item_name_field = 'distribution_line_items_attributes_0_item_id'
        select(item_type, from: first_item_name_field)
        find_all(".numeric")[0].set 1

        click_on "Add another item"
        find_all(".numeric")[1].set 3

        first("button", text: "Save").click

        expect(page).to have_css "td"
        item_row = find("td", text: item_type).find(:xpath, '..')

        # TODO: Find out how to test for item type and 4 without the dollar amounts.
        expect(item_row).to have_content("#{item_type} $1.00 $4.00 4")
      end
    end
  end

  # TODO: This should probably be in the Request resource specs, not Distribution
  context "When creating a distribution from a request" do
    it "sets the distribution id and fulfilled status on the request" do
      items = @storage_location.items.pluck(:id).sample(2)
      request_items = [{ "item_id" => items[0], "quantity" => 10 }, { "item_id" => items[1], "quantity" => 10 }]
      @request = create :request, organization: @organization, request_items: request_items

      visit @url_prefix + "/requests/#{@request.id}"
      click_on "Fulfill request"
      within "#new_distribution" do
        select @storage_location.name, from: "From storage location"
        choose "Delivery"
        click_on "Save"
      end

      expect(page).to have_content("Distribution Complete")

      @distribution = Distribution.last
      expect(@request.reload.distribution_id).to eq @distribution.id
      expect(@request.reload).to be_status_fulfilled
    end

    it "maintains the connection with the request even when there are initial errors" do
      items = @storage_location.items.pluck(:id).sample(2)
      request_items = [{ "item_id" => items[0], "quantity" => 1000000 }, { "item_id" => items[1], "quantity" => 10 }]
      @request = create :request, organization: @organization, request_items: request_items

      visit @url_prefix + "/requests/#{@request.id}"
      click_on "Fulfill request"
      within "#new_distribution" do
        select @storage_location.name, from: "From storage location"
        choose "Delivery"
        click_on "Save"
      end

      expect(page).to have_content("Sorry, we weren't able to save")
      find_all(".numeric")[0].set 1
      click_on "Save"

      expect(page).to have_content("Distribution Complete")

      @distribution = Distribution.last
      expect(@request.reload.distribution_id).to eq @distribution.id
      expect(@request.reload).to be_status_fulfilled
    end
  end

  context "via barcode entry" do
    before(:each) do
      initialize_barcodes
      visit @url_prefix + "/distributions/new"
    end

    it "allows users to add items via scanning them in by barcode", js: true do
      Barcode.boop(@existing_barcode.value)
      # the form should update
      qty = page.find(:xpath, '//input[@id="distribution_line_items_attributes_0_quantity"]').value

      expect(qty).to eq(@existing_barcode.quantity.to_s)
    end

    xit "a user can add items that do not yet have a barcode" do
      pending("fix this test")
      page.fill_in "_barcode-lookup-0", with: "123123123321\n"
      find('#_barcode-lookup-0').set("123123123321\n")

      page.fill_in "Quantity", with: "50"
      select "Adult Briefs (Large/X-Large)", from: "Item"
      page.fill_in "Barcode", with: "123123123321"

      click_on "Submit"

      visit @url_prefix + "/distributions/new"
      page.fill_in "_barcode-lookup-0", with: "123123123321\n"

      expect(page).to have_text("50")
    end
  end

  context "when filtering on the index page" do
    subject { @url_prefix + "/distributions" }
    let(:item_category) { create(:item_category) }
    let(:item1) { create(:item, name: "Good item", item_category: item_category) }
    let(:item2) { create(:item, name: "Crap item") }
    let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com") }
    let(:partner2) { create(:partner, name: "Not This Guy", email: "ntg@example.com") }

    it "filters by item id" do
      create(:distribution, :with_items, item: item1)
      create(:distribution, :with_items, item: item2)

      visit subject
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 2)
      # filter
      select(item1.name, from: "filters_by_item_id")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 1)

      # check for heading text
      expect(page).to have_css("table thead tr th", text: "Total #{item1.name}")
      # check for count update
      stored_item1_total = @storage_location.item_total(item1.id)
      expect(page).to have_css("table tbody tr td", text: stored_item1_total)
    end

    it "filters by item category id" do
      @organization.item_categories << item_category
      create(:distribution, :with_items, item: item1)
      create(:distribution, :with_items, item: item2)

      visit subject
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 2)
      # filter
      select(item_category.name, from: "filters_by_item_category_id")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 1)

      # check for heading text
      expect(page).to have_css("table thead tr th", text: "Total in #{item_category.name}")
      # check for count update
      stored_item1_total = @storage_location.item_total(item1.id)
      expect(page).to have_css("table tbody tr td", text: stored_item1_total)
    end

    it "filters by partner" do
      create(:distribution, partner: partner1)
      create(:distribution, partner: partner2)

      visit subject
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 2)
      # filter
      select(partner1.name, from: "filters_by_partner")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "filters by state" do
      distribution1 = create(:distribution, state: "scheduled")
      create(:distribution, state: "complete")

      visit subject
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 2)
      # filter
      select(distribution1.state.humanize, from: "filters_by_state")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 1)
    end

    it_behaves_like "Date Range Picker", Distribution, :issued_at

    it "should not display inactive storage locations in dropdown" do
      create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
      visit subject
      expect(page).to have_no_content "Inactive R Us"
    end
  end
end
