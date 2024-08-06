RSpec.feature "Distributions", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization, name: "Test Storage Location") }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let!(:partner) { create(:partner, organization: organization, name: "Test Partner") }

  before do
    sign_in(user)
    setup_storage_location(storage_location)
  end

  context "When going to the Pick Ups & Deliveries page" do
    let(:issued_at) { Time.current.utc.change(hour: 19, minute: 0).to_datetime }
    before do
      item1 = create(:item, value_in_cents: 1050, organization: organization)
      @distribution = create(:distribution, :with_items, item: item1, agency_rep: "A Person", organization: user.organization, issued_at: issued_at)
    end

    it "appears distribution in calendar with correct time & timezone" do
      visit schedule_distributions_path
      expect(page.find(".fc-event-time")).to have_content "7p"
      expect(page.find(".fc-event-title")).to have_content @distribution.partner.name
    end
  end

  context "When creating a new distribution manually" do
    context "when the delivery_method is not shipped" do
      it "Allows a distribution to be created and shipping cost field not visible" do
        visit new_distribution_path

        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        choose "Pick up"

        fill_in "Comment", with: "Take my wipes... please"
        fill_in "Distribution date", with: '01/01/2001 10:15:00 AM'

        # shipping cost field should not be visible
        expect { page.find_by_id("shipping_cost_div", wait: 2) }.to raise_error(Capybara::ElementNotFound)

        expect(PartnerMailerJob).to receive(:perform_later).once
        click_button "Save", match: :first

        expect(page).to have_selector('#distributionConfirmationModal')
        within "#distributionConfirmationModal" do
          expect(page).to have_content("You are about to create a distribution for")
          expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
          expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
          click_button "Yes, it's correct"
        end

        expect(page).to have_content "Distributions"
        expect(page.find(".alert-info")).to have_content "created"
      end
    end

    it "Displays a confirmation modal with combined items and allows user to return to the new form" do
      item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
      item.update!(on_hand_minimum_quantity: 5)
      TestInventory.create_inventory(organization,
        {
          storage_location.id => { item.id => 20 }
        })

      visit new_distribution_path
      select "Test Partner", from: "Partner"
      select "Test Storage Location", from: "From storage location"
      select2(page, 'distribution_line_items_item_id', item.name, position: 1)
      select "Test Storage Location", from: "distribution_storage_location_id"
      fill_in "distribution_line_items_attributes_0_quantity", with: 15

      # This will fill in another item row with the same item but an additional quantity of 3
      click_on "Add Another Item"
      quantity_fields = all('input[data-quantity]')
      second_quantity_field = quantity_fields[1]
      second_quantity_field&.fill_in(with: '3')

      click_button "Save"

      expect(page).to have_selector('#distributionConfirmationModal')
      within "#distributionConfirmationModal" do
        expect(page).to have_content("You are about to create a distribution for")
        expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
        expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
        expect(page).to have_content(item.name)
        # There are two line items in the form for the same quantity (15 + 3 = 18)
        expect(page).to have_content("18")
        click_button "No, I need to make changes"
      end

      expect(page).to have_current_path(new_distribution_path)
    end

    it "Does not display a confirmation modal when there are validation errors" do
      item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
      item.update!(on_hand_minimum_quantity: 5)
      TestInventory.create_inventory(organization,
        {
          storage_location.id => { item.id => 20 }
        })

      visit new_distribution_path
      # Forget to fill out partner
      select "Test Storage Location", from: "From storage location"
      select2(page, 'distribution_line_items_item_id', item.name, position: 1)
      select "Test Storage Location", from: "distribution_storage_location_id"
      fill_in "distribution_line_items_attributes_0_quantity", with: 6

      click_button "Save"

      expect(page).to have_css('.alert.error', text: /partner/i)

      # Fix validation error by filling in a partner
      select "Test Partner", from: "Partner"
      click_button "Save"

      # Now the confirmation modal should show up
      expect(page).to have_selector('#distributionConfirmationModal')
      within "#distributionConfirmationModal" do
        expect(page).to have_content("You are about to create a distribution for")
        expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
        expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
        expect(page).to have_content(item.name)
        expect(page).to have_content("6")
        click_button "Yes, it's correct"
      end

      expect(page).to have_content "Distributions"
      expect(page.find(".alert-info")).to have_content "created"
    end

    it "Displays a complete form after validation errors" do
      visit new_distribution_path

      # verify line items appear on initial load
      expect(page).to have_selector "#distribution_line_items"

      select "Test Partner", from: "Partner"
      expect do
        click_button "Save"
      end.not_to change { ActionMailer::Base.deliveries.count }

      # verify line items appear on reload
      expect(page).to have_content "New Distribution"
      expect(page).to have_selector "#distribution_line_items"
    end

    context "when the delivery_method is shipped and shipping cost is none-negative" do
      it "Allows a distribution to be created" do
        visit new_distribution_path

        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        choose "Shipped"

        # to check if shipping_cost field exist
        expect(page.find_by_id("shipping_cost_div")).not_to be_nil

        fill_in "Shipping cost", with: '12.05'
        fill_in "Comment", with: "Take my wipes... please"
        fill_in "Distribution date", with: '01/01/2001 10:15:00 AM'

        click_button "Save", match: :first

        expect(page).to have_selector('#distributionConfirmationModal')
        within "#distributionConfirmationModal" do
          expect(page).to have_content("You are about to create a distribution for")
          expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
          expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
          click_button "Yes, it's correct"
        end

        expect(page).to have_content "Distributions"
        expect(page.find(".alert-info")).to have_content "created"
      end
    end

    context "when the quantity is lower than the on hand minimum quantity" do
      it "should display an error" do
        item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
        item.update!(on_hand_minimum_quantity: 5)
        TestInventory.create_inventory(organization,
          {
            storage_location.id => { item.id => 20 }
          })

        visit new_distribution_path
        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        select2(page, 'distribution_line_items_item_id', item.name, position: 1)
        select "Test Storage Location", from: "distribution_storage_location_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: 18

        click_button "Save"

        expect(page).to have_selector('#distributionConfirmationModal')
        within "#distributionConfirmationModal" do
          expect(page).to have_content("You are about to create a distribution for")
          expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
          expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
          expect(page).to have_content(item.name)
          expect(page).to have_content("18")
          click_button "Yes, it's correct"
        end

        expect(page).not_to have_content('New Distribution')
        expect(page).to have_content("The following items have fallen below the minimum on hand quantity: #{item.name}")
      end
    end

    context "when the quantity is lower than the on hand recommended quantity" do
      it "should display an alert" do
        item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
        item.update!(on_hand_minimum_quantity: 1, on_hand_recommended_quantity: 5)
        TestInventory.create_inventory(organization,
          {
            storage_location.id => { item.id => 20 }
          })

        visit new_distribution_path
        select "Test Partner", from: "Partner"

        await_select2("#distribution_line_items_attributes_0_item_id") do
          select "Test Storage Location", from: "From storage location"
        end

        select item.name, from: "distribution_line_items_attributes_0_item_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: 18

        click_button "Save"

        expect(page).to have_selector('#distributionConfirmationModal')
        within "#distributionConfirmationModal" do
          expect(page).to have_content("You are about to create a distribution for")
          expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
          expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
          expect(page).to have_content(item.name)
          expect(page).to have_content("18")
          click_button "Yes, it's correct"
        end

        expect(page).to have_content("The following items have fallen below the recommended on hand quantity: #{item.name}")
      end
    end

    context "when there is insufficient inventory to fulfill the Distribution" do
      it "gracefully handles the error" do
        visit new_distribution_path

        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        choose "Delivery"

        fill_in "Comment", with: "Take my wipes... please"

        item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first
        quantity = item.quantity
        select item.name, from: "distribution_line_items_attributes_0_item_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: quantity * 2

        expect do
          click_button "Save", match: :first

          expect(page).to have_selector('#distributionConfirmationModal')
          within "#distributionConfirmationModal" do
            expect(page).to have_content("You are about to create a distribution for")
            expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
            expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
            expect(page).to have_content(item.name)
            expect(page).to have_content(quantity * 2)
            click_button "Yes, it's correct"
          end

          page.find('.alert')
        end.not_to change { Distribution.count }

        expect(page).to have_content("New Distribution")
        message = Event.read_events?(organization) ? 'Could not reduce quantity' : 'items exceed the available inventory'
        expect(page.find(".alert")).to have_content message
      end
    end
    context "when there is a default storage location" do
      it "automatically selects the default storage location" do
        organization.default_storage_location = storage_location.id
        visit new_distribution_path
        expect(find("#distribution_storage_location_id").text).to eq("Test Storage Location")
      end
    end
    it "should not display inactive storage locations in dropdown" do
      inactive_location = create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
      setup_storage_location(inactive_location)
      visit new_distribution_path
      expect(page).to have_no_content "Inactive R Us"
    end
  end

  it "errors if user does not fill storage_location" do
    visit new_distribution_path

    select "Test Partner", from: "Partner"
    select "", from: "From storage location"

    click_button "Save", match: :first

    expect(page).to have_css('.alert.error', text: /storage location/i)

    # 4438- Bug Fix
    select storage_location.name, from: "From storage location"
    expect(page).not_to have_css('#__add_line_item.disabled')
  end

  context "With an existing distribution" do
    let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", delivery_method: delivery_method, organization: user.organization) }
    let(:delivery_method) { "pick_up" }

    before do
      sign_in(organization_admin)
      visit distributions_path
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

      visit distributions_path
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
        message = Event.read_events?(organization) ? 'Could not reduce quantity' : 'items exceed the available inventory'
        expect(page).to have_content message
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

    context "when delivery method is not shipped" do
      it "should not display shipping_cost field" do
        click_on "Edit", match: :first

        # if element not found it will throw exception
        expect { page.find_by_id("shipping_cost_div", wait: 2) }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context "when delivery method is shipped and shipping cost is none negative" do
      let(:delivery_method) { "shipped" }

      it "should update distribution and display shipping_cost field" do
        click_on "Edit", match: :first

        # to check if shipping_cost field exist
        expect(page.find_by_id("shipping_cost_div")).not_to be_nil

        fill_in "Shipping cost", with: 12.05
        click_on "Save", match: :first
        expect(page).to have_content "Distributions"
        expect(page.find(".alert-info")).to have_content "Distribution updated!"
      end
    end

    context "when one of the items has been 'deleted'" do
      it "the user can still reclaim it", js: true do
        item = distribution.line_items.first.item
        item.destroy
        expect do
          accept_confirm do
            click_on "Reclaim"
          end
          page.find ".alert"
        end.to change { Distribution.count }.by(-1)
        expect(page).to have_content "reclaimed"
      end
    end
  end

  context "When attempting to edit a distribution" do
    context "after the distribution issued_at has passed or it has been marked complete" do
      let!(:past_distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: user.organization, issued_at: Time.zone.yesterday, state: :scheduled) }
      let!(:complete_distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: user.organization, issued_at: Time.zone.today, state: :complete) }

      it "does not contain a Edit button" do
        visit distributions_path
        expect(page).not_to have_button("Edit")
      end

      it "cannot be accessed directly" do
        visit edit_distribution_path(past_distribution.id)
        expect(page.find(".alert-danger")).to have_content "you must be an organization admin"
        visit edit_distribution_path(complete_distribution.id)
        expect(page.find(".alert-danger")).to have_content "you must be an organization admin"
      end
    end

    context "when logged as Admin" do
      before do
        # this will fail if it runs on January 1
        # since we're creating a distribution yesterday (i.e. last year)
        # and it won't show any distributions for this year
        travel_to Time.zone.local(2023, 5, 5)
        sign_in(organization_admin)
      end

      let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: user.organization, issued_at: Time.zone.today.prev_day, state: :complete) }

      it "can click on Edit button and a warning appears " do
        visit distributions_path
        click_on "Edit", match: :first
        expect(page.find(".alert-warning")).to have_content "The current date is past the date this distribution was scheduled for."
      end

      it "can be accessed directly" do
        visit edit_distribution_path(distribution.id)
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
      @distribution1 = create(:distribution, :with_items, item: item1, agency_rep: "A Person", organization: user.organization)
      create(:distribution, :with_items, item: item2, agency_rep: "A Person", organization: user.organization)
      @distribution3 = create(:distribution, :with_items, item: item3, agency_rep: "A Person", organization: user.organization)
      visit distributions_path
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
      visit distribution_path(@distribution1.id)
      expect(page).to have_content "$10.50"
    end

    it 'the user sees total value on show page' do
      # 100 items * 10.5
      visit distribution_path(@distribution1.id)
      expect(page).to have_content "$1,050"
    end
  end

  context "When showing a individual distribution" do
    let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", organization: user.organization, issued_at: Time.zone.today, state: :complete, delivery_method: "pick_up") }

    before { visit distribution_path(distribution.id) }

    it "Show partner name in title" do
      expect(page).to have_content("Distribution from #{distribution.storage_location.name} to #{distribution.partner.name}")
    end
  end

  context "When creating a distribution from a donation" do
    let(:donation) { create :donation, :with_items }
    before do
      visit donation_path(donation)
      sign_in(organization_admin)
      click_on "Start a new Distribution"
      within "#new_distribution" do
        select "Test Partner", from: "Partner"
        choose "Pick up"
        click_button "Save"
      end

      expect(page).to have_selector('#distributionConfirmationModal')
      within "#distributionConfirmationModal" do
        expect(page).to have_content("You are about to create a distribution for")
        expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
        expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text(donation.storage_location.name)
        donation.line_items.each do |li|
          expect(page).to have_content(li.name)
          expect(page).to have_content(li.quantity)
        end
        click_button "Yes, it's correct"
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
          first("[data-quantity]").set 13
        end
        click_on "Save"
        expect(page).to have_content "Distribution updated!"
        expect(page).to have_content 13
      end

      it "User creates a distribution from a donation then tries to make the quantity too big", js: true do
        within ".distribution_line_items_quantity" do
          first("[data-quantity]").set 999_999
        end
        click_on "Save"

        expect(page).to have_no_content "Distribution updated!"
        message = 'items exceed the available inventory'
        number = 999_999
        if Event.read_events?(organization)
          message = 'Could not reduce quantity'
          number = 999_899
        end
        expect(page).to have_content(/#{message}/i)
        expect(page).to have_content number, count: 1
        within ".alert" do
          expect(page).to have_content number
        end
        expect(Distribution.first.line_items.count).to eq 1
      end

      it "User creates duplicate line items" do
        item = @distribution.line_items.first.item
        select2(page, 'distribution_line_items_item_id', item.name, position: 1)
        find_all("[data-quantity]")[0].set 1

        click_on "Add Another Item"

        select2(page, 'distribution_line_items_item_id', item.name, position: 2)
        new_select = find_all("[data-quantity]")[1]
        expect(new_select.value).to eq("")
        find_all("[data-quantity]")[1].set 3

        first("button", text: "Save").click

        expect(page).to have_css "td"
        item_row = find("td", text: item.name).find(:xpath, '..')

        # TODO: Find out how to test for item type and 4 without the dollar amounts.
        expect(item_row).to have_content("#{item.name}\t$1.00\t$4.00\t4")
      end
    end
  end

  # TODO: This should probably be in the Request resource specs, not Distribution
  context "When creating a distribution from a request" do
    it "sets the distribution id and fulfilled status on the request" do
      items = storage_location.items.pluck(:id).sample(2)
      request_items = [{ "item_id" => items[0], "quantity" => 10 }, { "item_id" => items[1], "quantity" => 10 }]
      @request = create :request, organization: organization, request_items: request_items

      visit request_path(id: @request.id)
      click_on "Fulfill request"
      within "#new_distribution" do
        select "Test Storage Location", from: "From storage location"
        choose "Delivery"
        click_on "Save"
      end

      expect(page).to have_selector('#distributionConfirmationModal')
      within "#distributionConfirmationModal" do
        expect(page).to have_content("You are about to create a distribution for")
        expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text(Request.last.partner.name)
        expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
        request_items.each do |item|
          expect(page).to have_content(Item.find(item["item_id"]).name)
          expect(page).to have_content(item["quantity"])
        end
        click_button "Yes, it's correct"
      end

      expect(page).to have_content("Distribution Complete")

      @request = Request.last
      @distribution = Distribution.last
      expect(@request.distribution_id).to eq @distribution.id
      expect(@request).to be_status_fulfilled
    end

    it "maintains the connection with the request even when there are initial errors" do
      items = storage_location.items.pluck(:id).sample(2)
      request_items = [{ "item_id" => items[0], "quantity" => 1000000 }, { "item_id" => items[1], "quantity" => 10 }]
      @request = create :request, organization: organization, request_items: request_items

      visit request_path(id: @request.id)
      click_on "Fulfill request"
      within "#new_distribution" do
        select "Test Storage Location", from: "From storage location"
        choose "Delivery"
        click_on "Save"
      end

      expect(page).to have_selector('#distributionConfirmationModal')
      within "#distributionConfirmationModal" do
        expect(page).to have_content("You are about to create a distribution for")
        expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text(Request.last.partner.name)
        expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
        request_items.each do |item|
          expect(page).to have_content(Item.find(item["item_id"]).name)
          expect(page).to have_content(item["quantity"])
        end
        click_button "Yes, it's correct"
      end

      expect(page).to have_content("Sorry, we weren't able to save")
      find_all("[data-quantity]")[0].set 1

      click_on "Save"

      expect(page).to have_selector('#distributionConfirmationModal')
      within "#distributionConfirmationModal" do
        expect(page).to have_content("You are about to create a distribution for")
        expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text(Request.last.partner.name)
        expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
        request_items.each do |item|
          expect(page).to have_content(Item.find(item["item_id"]).name)
        end
        click_button "Yes, it's correct"
      end

      expect(page).to have_content("Distribution Complete")

      @request = Request.last
      @distribution = Distribution.last
      expect(@request.distribution_id).to eq @distribution.id
      expect(@request).to be_status_fulfilled
    end
  end

  context "via barcode entry" do
    let(:existing_barcode) { create(:barcode_item) }
    let(:item_with_barcode) { existing_barcode.item }
    let(:item_no_barcode) { create(:item) }

    it "allows users to add items via scanning them in by barcode", js: true do
      visit new_distribution_path

      Barcode.boop(existing_barcode.value)
      # the form should update
      page.find_field(id: "distribution_line_items_attributes_0_quantity", with: "50")
      qty = page.find(:xpath, '//input[@id="distribution_line_items_attributes_0_quantity"]').value
      expect(qty).to eq(existing_barcode.quantity.to_s)
    end

    context 'when a specific item exists' do
      before do
        create(:item, organization: organization, name: "VerySpecificItem")
        visit new_distribution_path
      end

      it "a user can add items that do not yet have a barcode" do
        barcode_value = "123123123321"
        Barcode.boop(barcode_value)

        within ".modal-content" do
          page.fill_in "Quantity", with: "51"
          select "VerySpecificItem", from: "Item"
          click_on "Save"
        end

        visit new_distribution_path
        Barcode.boop(barcode_value)

        expect(page).to have_text("VerySpecificItem")
        expect(page).to have_field("Quantity", with: "51")
      end
    end
  end

  context "when filtering on the index page" do
    subject { distributions_path }
    let(:item_category) { create(:item_category) }
    let(:item1) { create(:item, name: "Good item", item_category: item_category, organization: organization) }
    let(:item2) { create(:item, name: "Crap item", organization: organization) }
    let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com", organization: organization) }
    let(:partner2) { create(:partner, name: "Not This Guy", email: "ntg@example.com", organization: organization) }

    it "filters by item id" do
      create(:distribution, :with_items, item: item1)
      create(:distribution, :with_items, item: item2)

      visit subject
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 2)
      # filter
      select(item1.name, from: "filters[by_item_id]")
      click_button("Filter")
      # check for filtered distributions
      expect(page).to have_css("table tbody tr", count: 1)

      # check for heading text
      expect(page).to have_css("table thead tr th", text: "Total #{item1.name}")
      # check for count update
      stored_item1_total = storage_location.item_total(item1.id)
      expect(page).to have_css("table tbody tr td", text: stored_item1_total)
    end

    context "with fresh items" do
      let(:organization) { create(:organization) }
      let(:user) { create(:user, organization: organization) }
      let(:storage_location) { create(:storage_location, organization: organization) }
      let(:item_category) { create(:item_category, organization: organization) }
      let(:item1) { create(:item, name: "Good item", item_category: item_category, organization: organization) }
      let(:item2) { create(:item, name: "Crap item", organization: organization) }
      let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com", organization: organization) }
      let(:partner2) { create(:partner, name: "Not This Guy", email: "ntg@example.com", organization: organization) }

      it "filters by item category id" do
        setup_storage_location(storage_location)

        sign_out(user)
        sign_in(user)

        create(:distribution, :with_items, item: item1, organization: organization)
        create(:distribution, :with_items, item: item2, organization: organization)

        visit distributions_path
        # check for all distributions
        expect(page).to have_css("table tbody tr", count: 2)
        # filter
        select(item_category.name, from: "filters[by_item_category_id]")
        click_button("Filter")
        # check for filtered distributions
        expect(page).to have_css("table tbody tr", count: 1)

        # check for heading text
        expect(page).to have_css("table thead tr th", text: "Total in #{item_category.name}")
        # check for count update
        stored_item1_total = storage_location.item_total(item1.id)
        expect(page).to have_css("table tbody tr td", text: stored_item1_total)
      end
    end

    it "filters by partner" do
      create(:distribution, partner: partner1)
      create(:distribution, partner: partner2)

      visit subject
      # check for all distributions
      expect(page).to have_css("table tbody tr", count: 2)
      # filter
      select(partner1.name, from: "filters[by_partner]")
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
      select(distribution1.state.humanize, from: "filters[by_state]")
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

  it "allows completion of corrected distribution with depleted inventory item" do
    visit new_distribution_path
    item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
    TestInventory.create_inventory(organization,
      {
        storage_location.id => { item.id => 20 }
      })

    select "Test Partner", from: "Partner"
    select "Test Storage Location", from: "From storage location"
    choose "Delivery"
    select item.name, from: "distribution_line_items_attributes_0_item_id"
    fill_in "distribution_line_items_attributes_0_quantity", with: 15

    click_button "Save"

    expect(page).to have_selector('#distributionConfirmationModal')
    within "#distributionConfirmationModal" do
      expect(page).to have_content("You are about to create a distribution for")
      expect(find(:element, "data-testid": "distribution-confirmation-partner")).to have_text("Test Partner")
      expect(find(:element, "data-testid": "distribution-confirmation-storage")).to have_text("Test Storage Location")
      expect(page).to have_content(item.name)
      expect(page).to have_content("15")
      click_button "Yes, it's correct"
    end

    click_link "Make a Correction"

    fill_in "distribution_line_items_attributes_0_quantity", with: 20

    click_button "Save"
    # At this point the distribution was already saved and edited,
    # therefore the confirmation modal does not appear here.

    expect(page).to have_content("Distribution Complete")
    expect(page).to have_link("Distribution Complete")

    expect(storage_location.inventory_items.first.quantity).to eq(0)
    expect(View::Inventory.new(organization.id)
      .quantity_for(item_id: item.id, storage_location: storage_location.id)).to eq(0)

    click_link "Distribution Complete"
    expect(page).to have_content('Distribution')

    expect(page).to have_content("This distribution has been marked as being completed!")
  end
end
