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

    # FullCalendar's own toolbar is three buttons filled rgb(44,62,80) at a 4px radius -- a page's
    # worth of primary-looking chrome for moving the month. The grid is restyled in CSS the way
    # select2 is; the toolbar is ours outright, so a library upgrade cannot silently revert it.
    it "uses the app's own toolbar, not the library's" do
      visit schedule_distributions_path
      expect(page).to have_css("[data-calendar-target='title']", text: /\w+ \d{4}/)

      expect(page).to have_no_css(".fc-toolbar")
      expect(page).to have_no_css(".fc-button")

      expect(page).to have_button("Today")
      expect(page).to have_button("Prev")
      expect(page).to have_button("Next")
    end

    it "moves the month, and says so out loud" do
      visit schedule_distributions_path
      # The heading is empty until FullCalendar reports the range it settled on, so wait for a real
      # month before reading it -- otherwise `before` is "" and the comparison is vacuous.
      expect(page).to have_css("[data-calendar-target='title']", text: /\w+ \d{4}/)

      title = page.find("[data-calendar-target='title']")
      # The buttons change the grid without navigating, so nothing else would announce the change.
      expect(title[:"aria-live"]).to eq("polite")

      before = title.text
      click_on "Next"
      expect(page).to have_no_css("[data-calendar-target='title']", text: before)

      click_on "Today"
      expect(page).to have_css("[data-calendar-target='title']", text: before)
    end

    # FullCalendar renders "+2 more" as an <a> with no href, carrying aria-expanded and an empty
    # aria-controls -- neither allowed on an element with no role. axe reports it CRITICAL, and only
    # once a day is crowded enough to overflow, which db:seed:calendar now makes happen.
    it "names the overflow link as the button it already behaves like" do
      # Six on one day; the month cell shows one and folds the rest behind "+N more".
      6.times { |i| create(:distribution, organization: organization, issued_at: issued_at + 3.days + i.hours) }
      visit schedule_distributions_path

      expect(page).to have_css(".fc-daygrid-more-link")
      link = page.first(".fc-daygrid-more-link")
      expect(link[:role]).to eq("button")
      expect(link[:"aria-controls"]).to be_nil
    end

    # Two axes, because these are two questions. They used to be one row of three -- Month, Week,
    # List -- where "List" named a shape and its neighbours named a duration, so nothing said how
    # much time it covered. No Day view: over a year, 22 days had any distribution at all, mean 1.9,
    # and 13 of those held exactly one.
    it "offers a duration and a layout, and no Day" do
      visit schedule_distributions_path

      expect(page).to have_button("Month")
      expect(page).to have_button("Week")
      expect(page).to have_button("Grid")
      expect(page).to have_button("List")
      expect(page).to have_no_button("Day")
      expect(page).to have_css("[data-calendar-range][aria-pressed='true']", text: "Month")
      expect(page).to have_css("[data-calendar-layout][aria-pressed='true']", text: "Grid")
    end

    # All four combinations, including a whole month as one list -- which the three-button switcher
    # could not express at all, and which is the obvious thing to want for a monthly reconciliation.
    it "reaches all four combinations of duration and layout" do
      {
        "month" => {"grid" => ".fc-dayGridMonth-view", "list" => ".fc-listMonth-view"},
        "week" => {"grid" => ".fc-dayGridWeek-view", "list" => ".fc-listWeek-view"}
      }.each do |range, layouts|
        layouts.each do |layout, selector|
          visit "#{schedule_distributions_path}?range=#{range}&layout=#{layout}"
          expect(page).to have_css(selector), "expected #{range}/#{layout} to render #{selector}"
        end
      end
    end

    # The parameter is `layout` and not the obvious `format`, because `format` is reserved by Rails
    # routing for the response MIME type: `?format=grid` raised ActionController::UnknownFormat, a
    # 406, before the view rendered at all.
    it "does not collide with Rails' own format parameter" do
      visit "#{schedule_distributions_path}?range=week&layout=list"

      expect(page).to have_css(".fc-listWeek-view")
      expect(page).to have_no_content("UnknownFormat")
    end

    # The choice lives in the URL, not localStorage: design.md settled that for page tabs, and the
    # argument is unchanged -- it is how a view becomes something you can link to and go back from.
    it "puts both axes in the URL, even when only one was clicked" do
      visit schedule_distributions_path
      click_on "List"

      # Both, so a shared link carries the whole answer rather than half of it plus a default that
      # depends on the reader's window width.
      expect(page).to have_current_path(/range=month/)
      expect(page).to have_current_path(/layout=list/)
      expect(page).to have_css(".fc-listMonth-view")

      # And a link straight to it opens there.
      visit "#{schedule_distributions_path}?range=week&layout=grid"
      expect(page).to have_css(".fc-dayGridWeek-view")
      expect(page).to have_css("[data-calendar-range][aria-pressed='true']", text: "Week")
      expect(page).to have_css("[data-calendar-layout][aria-pressed='true']", text: "Grid")
    end

    # `?view=` was the parameter before the switcher split in two. Links shared while it existed
    # still open on what they meant.
    it "still honours the old view parameter" do
      visit "#{schedule_distributions_path}?view=list"
      expect(page).to have_css(".fc-listWeek-view")

      visit "#{schedule_distributions_path}?view=week"
      expect(page).to have_css(".fc-dayGridWeek-view")

      visit "#{schedule_distributions_path}?view=month"
      expect(page).to have_css(".fc-dayGridMonth-view")
    end

    it "goes back to the previous view" do
      visit schedule_distributions_path
      expect(page).to have_css(".fc-dayGridMonth-view")

      click_on "Week"
      # Wait for the history entry, not only for the rendered class. Going back before pushState has
      # been committed leaves the assertions racing the popstate handler.
      expect(page).to have_current_path(/range=week/)
      expect(page).to have_css(".fc-dayGridWeek-view")

      page.go_back

      # pushState rather than replaceState, or Back would leave the URL behind and the view alone.
      expect(page).to have_current_path(schedule_distributions_path, ignore_query: false)
      expect(page).to have_css(".fc-dayGridMonth-view")
      expect(page).to have_css("[data-calendar-range][aria-pressed='true']", text: "Month")
    end

    # A month grid on a phone is unreadable, so a narrow window opens on the week, as a list --
    # which is what this page already fell back to before there was any choice about it.
    it "defaults a narrow window to a week, as a list" do
      page.driver.resize(375, 800)
      visit schedule_distributions_path

      expect(page).to have_css(".fc-listWeek-view")
      expect(page).to have_css("[data-calendar-range][aria-pressed='true']", text: "Week")
      expect(page).to have_css("[data-calendar-layout][aria-pressed='true']", text: "List")
    end

    # The bug the split was born from: "Week" once meant a grid above 992px and a list below it, and
    # since the list was also the narrow default, Week arrived pressed and its button did nothing.
    # Both grids are reachable in a narrow window now.
    it "reaches a grid in a narrow window" do
      page.driver.resize(900, 800)
      visit schedule_distributions_path
      expect(page).to have_css(".fc-listWeek-view")

      click_on "Grid"

      expect(page).to have_css(".fc-dayGridWeek-view")
      expect(page).to have_css("[data-calendar-layout][aria-pressed='true']", text: "Grid")
    end

    # `defaultView` and `eventLimit` are FullCalendar 4 spellings, and this app is on 6, so both
    # were being ignored: at 375px it rendered the month grid, never the list.
    it "shows a list rather than a month grid when the window is too narrow for one" do
      page.driver.resize(375, 800)
      visit schedule_distributions_path

      expect(page).to have_css(".fc-list")
      expect(page).to have_no_css(".fc-daygrid")
    end

    # A list draws only the days that hold something -- FullCalendar has no option for the empty
    # ones -- so a week with one distribution renders one row, which reads as "there is one
    # distribution, ever". Measured before this: the week of 7 September drew a single line under a
    # heading saying "Sep 7 – 13".
    it "says what the list covers and how much of it is empty" do
      visit "#{schedule_distributions_path}?range=week&layout=list"

      # `have_css(text:)` rather than `find` then read `.text`: find waits for the element, which
      # the server renders empty, and the controller fills it a beat later.
      expect(page).to have_css("[data-calendar-target='caption']",
        text: issued_at.to_date.strftime("%B"))
      expect(page).to have_css("[data-calendar-target='caption']", text: /\d+ of 7 days/)
    end

    it "counts a single day in the singular" do
      # The only distribution this organization has is the one created above, so the week holds
      # exactly one day -- the case that reads as "there is one distribution, ever". Deliberately
      # not `Distribution.destroy_all` to arrange that: nothing on the model publishes the
      # compensating event, so it strands stock. See CLAUDE.md.
      visit "#{schedule_distributions_path}?range=week&layout=list"

      expect(page).to have_css("[data-calendar-target='caption']",
        text: "1 of 7 days has a distribution")
    end

    it "names the month, not a span of days, when the list is a month" do
      visit "#{schedule_distributions_path}?range=month&layout=list"

      expect(page).to have_css("[data-calendar-target='caption']",
        text: /#{issued_at.strftime("%B %Y")} · \d+ of \d+ days/)
    end

    # In a grid the empty days are already on screen as empty cells, so the same sentence would be
    # restating the picture.
    it "hides the caption in the grids" do
      visit "#{schedule_distributions_path}?range=month&layout=grid"
      expect(page).to have_css(".fc-dayGridMonth-view")

      expect(page).to have_no_css("[data-calendar-target='caption']", visible: true)
    end

    # Prev and Next move one step, so before this the only way to reach a month in another year was
    # to click through every month between here and there.
    #
    # Matched by id rather than by the `aria-label`, which Capybara does not look at unless
    # `enable_aria_label` is on -- it is not, and this file already had to work around that once.
    it "jumps to a month in another year" do
      # The year list is bounded by the data, so there has to be data in the other year.
      create(:distribution, organization: organization, issued_at: issued_at - 1.year)
      visit schedule_distributions_path
      expect(page).to have_css("[data-calendar-target='title']", text: /\w+ #{issued_at.year}/)

      select (issued_at.year - 1).to_s, from: "calendar_year"
      select "March", from: "calendar_month"

      expect(page).to have_css("[data-calendar-target='title']", text: "March #{issued_at.year - 1}")
    end

    # The selects drive the calendar and follow it: Today, Prev, Next and a view change all move the
    # range, and a control reading August while the grid shows October is worse than no control.
    it "keeps the month and year selects on whatever the calendar is showing" do
      visit schedule_distributions_path
      # Text, not just the element: the server renders the h2 empty and `datesSet` fills it once
      # Stimulus connects, so waiting on presence alone races the controller.
      expect(page).to have_css("[data-calendar-target='title']", text: /\w/)

      click_on "Prev"

      previous_month = issued_at.to_date.prev_month
      expect(page).to have_css("[data-calendar-target='title']",
        text: previous_month.strftime("%B %Y"))
      expect(page).to have_select("calendar_month", selected: previous_month.strftime("%B"))
      expect(page).to have_select("calendar_year", selected: previous_month.year.to_s)
    end

    # The year list is bounded by the organization's own distributions, so Prev and Next can walk off
    # either end of it -- and a select showing a year the calendar is not on is a lie.
    it "adds the year when stepping past the end of the list" do
      visit schedule_distributions_path
      # Text, not just the element: the server renders the h2 empty and `datesSet` fills it once
      # Stimulus connects, so waiting on presence alone races the controller.
      expect(page).to have_css("[data-calendar-target='title']", text: /\w/)

      select "December", from: "calendar_month"
      expect(page).to have_css("[data-calendar-target='title']", text: "December #{issued_at.year}")

      click_on "Next"

      expect(page).to have_css("[data-calendar-target='title']", text: "January #{issued_at.year + 1}")
      expect(page).to have_select("calendar_year", selected: (issued_at.year + 1).to_s)
    end

    # Today stays pressable even while today is on screen, where it does nothing. It was dimmed with
    # `aria-disabled` for a day and that is reverted -- see docs/design-decisions.md. The case
    # against disabled controls is aimed at ones that gate a task, and every calendar a reader
    # already uses keeps Today live. This spec exists so the reversal is not undone by accident.
    it "keeps Today pressable even while today is already on screen" do
      %w[month week list].each do |view|
        visit "#{schedule_distributions_path}?view=#{view}"
        # Text, not just the element: the server renders the h2 empty and `datesSet` fills it once
        # Stimulus connects, so waiting on presence alone races the controller.
        expect(page).to have_css("[data-calendar-target='title']", text: /\w/)

        button = page.find_button("Today")
        expect(button[:disabled]).to be_falsey, "expected Today to stay live in the #{view} view"
        expect(button["aria-disabled"]).to be_nil
      end
    end

    it "takes you home from another month" do
      visit schedule_distributions_path
      # Text, not just the element: the server renders the h2 empty and `datesSet` fills it once
      # Stimulus connects, so waiting on presence alone races the controller.
      expect(page).to have_css("[data-calendar-target='title']", text: /\w/)
      home = page.find("[data-calendar-target='title']").text

      click_on "Next"
      expect(page).to have_no_css("[data-calendar-target='title']", text: home)

      click_on "Today"
      expect(page).to have_css("[data-calendar-target='title']", text: home)
    end

    # FullCalendar puts fc-day-today on the list row, but --fc-today-bg-color only reaches day
    # cells, so the list -- the default view on a phone -- marked today nowhere at all. Measured
    # before the fix: rgba(0, 0, 0, 0).
    it "marks today in the list view" do
      visit "#{schedule_distributions_path}?view=list"
      expect(page).to have_css(".fc-list")

      expect(page).to have_css(".fc-list-day.fc-day-today .fc-list-day-cushion")
      # The painted colour, not the class -- the class was there before the fix and painted nothing.
      background = page.evaluate_script(<<~JS)
        getComputedStyle(
          document.querySelector(".fc-list-day.fc-day-today .fc-list-day-cushion")
        ).backgroundColor
      JS
      expect(background).to eq("rgb(238, 242, 255)")
    end

    # Prev and Next move a month in the month view and a week in the other two, so one fixed
    # "Previous month" would be wrong in two views out of three.
    #
    # By CSS, because the accessible name is an `aria-label` and Capybara only matches those with
    # `enable_aria_label` on. The visible word stays inside the name, which is what 2.5.3 asks.
    it "names what Prev and Next actually step" do
      visit schedule_distributions_path
      # The title has text only once the controller has connected. The aria-label assertions below
      # would pass without it -- "Previous month" is what the *server* renders -- and then the click
      # would race the controller, which is how this failed once in a full-suite run.
      expect(page).to have_css("[data-calendar-target='title']", text: /\w/)
      expect(page).to have_css("button[aria-label='Previous month']")
      expect(page).to have_css("button[aria-label='Next month']")

      click_on "Week"

      expect(page).to have_css(".fc-dayGridWeek-view")
      expect(page).to have_css("button[aria-label='Previous week']")
      expect(page).to have_css("button[aria-label='Next week']")

      # The layout does not change what Prev and Next step, only the duration does.
      click_on "List"
      expect(page).to have_css(".fc-listWeek-view")
      expect(page).to have_css("button[aria-label='Previous week']")
    end
  end

  context "When creating a new distribution manually" do
    context "when the delivery_method is not shipped" do
      it "Allows a distribution to be created and shipping cost field not visible" do
        visit new_distribution_path

        open_filters
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
        expect(page.find("[data-flash-tone='info']")).to have_content "created"
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
      open_filters
      select "Test Partner", from: "Partner"
      select "Test Storage Location", from: "From storage location"
      select2(page, 'distribution_line_items_item_id', item.name, position: 1)
      select "Test Storage Location", from: "distribution_storage_location_id"
      fill_in "distribution_line_items_attributes_0_quantity", with: 15

      # This will fill in another item row with the same item but an additional quantity of 3
      click_on "Add another item"
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

      expect(page).to have_css("[data-error-summary]", text: /partner/i)

      # Fix validation error by filling in a partner
      open_filters
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
      expect(page.find("[data-flash-tone='info']")).to have_content "created"
    end

    # Issue #4644
    it "Disables confirmation and modal close buttons after clicking confirm" do
      item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
      item.update!(on_hand_minimum_quantity: 5)
      TestInventory.create_inventory(organization,
        {
          storage_location.id => { item.id => 20 }
        })

      visit new_distribution_path
      open_filters
      select "Test Partner", from: "Partner"
      select "Test Storage Location", from: "From storage location"
      select2(page, 'distribution_line_items_item_id', item.name, position: 1)
      select "Test Storage Location", from: "distribution_storage_location_id"
      fill_in "distribution_line_items_attributes_0_quantity", with: 15

      click_button "Save"

      # Disable form submission so form doesn't immediately submit and we can check button state
      page.execute_script("$('form#new_distribution').attr('action', 'javascript: void(0);');")

      click_button(id: "modalYes")

      expect(page).to have_button(id: "modalYes", visible: false, disabled: true)
      expect(page).to have_button(id: "modalNo", visible: false, disabled: true)
      expect(page).to have_button(id: "modalClose", visible: false, disabled: true)
    end

    it "Displays a complete form after validation errors" do
      visit new_distribution_path

      # verify line items appear on initial load
      expect(page).to have_selector "#distribution_line_items"

      open_filters
      select "Test Partner", from: "Partner"
      expect do
        click_button "Save"
      end.not_to change { ActionMailer::Base.deliveries.count }

      # verify line items appear on reload
      expect(page).to have_content "New distribution"
      expect(page).to have_selector "#distribution_line_items"
    end

    context "when the delivery_method is shipped and shipping cost is none-negative" do
      it "Allows a distribution to be created" do
        visit new_distribution_path

        open_filters
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
        expect(page.find("[data-flash-tone='info']")).to have_content "created"
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
        open_filters
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
        expect(page).to have_content("The following items have fallen below the minimum on hand quantity, bank-wide: #{item.name}")
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
        open_filters
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

        expect(page).to have_content("The following items have fallen below the recommended on hand quantity, bank-wide: #{item.name}")
      end
    end

    context "when there is insufficient inventory to fulfill the Distribution" do
      it "gracefully handles the error" do
        visit new_distribution_path

        open_filters
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

          page.find('[data-flash]')
        end.not_to change { Distribution.count }

        expect(page).to have_content("New distribution")
        expect(page.find("[data-flash]")).to have_content('Could not reduce quantity')
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

    open_filters
    select "Test Partner", from: "Partner"
    select "", from: "From storage location"

    click_button "Save", match: :first

    expect(page).to have_css("[data-error-summary]", text: /storage location/i)

    # 4438- Bug Fix
    select storage_location.name, from: "From storage location"
    expect(page).not_to have_css('#__add_line_item.disabled')
  end

  context "With an existing distribution" do
    let!(:distribution) { create(:distribution, :with_items, agency_rep: "A Person", delivery_method: delivery_method, organization: user.organization, reminder_email_enabled: true) }
    let(:delivery_method) { "pick_up" }
    let!(:request) { create(:request, distribution: distribution) }

    before do
      sign_in(organization_admin)
      visit distributions_path
    end

    it "the user can make changes" do
      click_row_action "Edit"
      fill_in "Agency representative", with: "SOMETHING DIFFERENT"
      click_on "Save", match: :first
      click_button "Yes, it's correct"
      # Make Capybara wait for events to finish before checking Db.
      expect(page).to have_content("SOMETHING DIFFERENT")

      distribution.reload
      expect(distribution.agency_rep).to eq("SOMETHING DIFFERENT")
    end

    it "the user can view related request" do
      click_row_action "View request"

      expect(page).to have_content "Request from #{distribution.request.partner.name}"
    end

    it "sends an email if reminders are enabled" do
      job = double('fake_job')
      allow(DistributionMailer).to receive(:reminder_email).and_return(job)
      allow(job).to receive(:deliver_later)

      visit distributions_path
      click_row_action "Edit"
      fill_in "Agency representative", with: "SOMETHING DIFFERENT"
      click_on "Save", match: :first
      click_button "Yes, it's correct"
      distribution.reload
      expect(job).to have_received(:deliver_later)
    end

    it "allows the user can change the issued_at date" do
      click_row_action "Edit"
      expect do
        fill_in "Distribution date", with: Time.zone.parse("2001-10-01 10:00")

        click_on "Save", match: :first
        click_button "Yes, it's correct"
        distribution.reload
      end.to change { distribution.issued_at }.to(Time.zone.parse("2001-10-01 10:00"))
    end

    it "disallows the user from changing the quantity above the inventory quantity" do
      click_row_action "Edit"
      expect do
        fill_in 'distribution_line_items_attributes_0_quantity', with: distribution.line_items.first.quantity + 300
        click_on "Save", match: :first
        click_button "Yes, it's correct"
      end.not_to change { distribution.line_items.first.quantity }
      within "[data-flash]" do
        expect(page).to have_content('Could not reduce quantity')
      end
    end

    it "the user can reclaim it" do
      expect do
        accept_confirm_dialog do
          click_row_action "Reclaim"
        end
        expect(page).to have_content "reclaimed"
      end.to change { Distribution.count }.by(-1)
    end

    context "when delivery method is not shipped" do
      it "should not display shipping_cost field" do
        click_row_action "Edit"

        # if element not found it will throw exception
        expect { page.find_by_id("shipping_cost_div", wait: 2) }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context "when delivery method is shipped and shipping cost is none negative" do
      let(:delivery_method) { "shipped" }

      it "should update distribution and display shipping_cost field" do
        click_row_action "Edit"

        # to check if shipping_cost field exist
        expect(page.find_by_id("shipping_cost_div")).not_to be_nil

        fill_in "Shipping cost", with: 12.05
        click_on "Save", match: :first
        click_button "Yes, it's correct"
        expect(page).to have_content "Distributions"
        expect(page.find("[data-flash-tone='info']")).to have_content "Distribution updated!"
      end
    end

    context "when one of the items has been 'deleted'" do
      it "the user can still reclaim it", js: true do
        item = distribution.line_items.first.item
        item.destroy
        expect do
          accept_confirm_dialog do
            click_row_action "Reclaim"
          end
          page.find "[data-flash]"
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
        expect(page.find("[data-flash-tone='danger']")).to have_content "you must be an organization admin"
        visit edit_distribution_path(complete_distribution.id)
        expect(page.find("[data-flash-tone='danger']")).to have_content "you must be an organization admin"
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
        click_row_action "Edit"
        expect(page).to have_content "The current date is past the date this distribution was scheduled for."
      end

      it "can be accessed directly" do
        visit edit_distribution_path(distribution.id)
        expect(page).to have_no_css("[data-flash-tone='danger']")
        expect(page).to have_content "The current date is past the date this distribution was scheduled for."
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
      click_on "Start a distribution"
      within "#new_distribution" do
        open_filters
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
      expect(page.find("[data-flash-tone='info']")).to have_content "reated"
      expect(Distribution.first.line_items.count).to eq 1
    end

    context "when editing that distribution" do
      before do
        @distribution = Distribution.last
        expect(page).to have_current_path(distribution_path(@distribution.id))
        click_on "Make a correction"
      end

      it "User creates a distribution from a donation then edits it" do
        within ".distribution_line_items_quantity" do
          first("[data-quantity]").set 13
        end
        click_on "Save"
        click_button "Yes, it's correct"
        expect(page).to have_content "Distribution updated!"
        expect(page).to have_content 13
      end

      it "User creates a distribution from a donation then tries to make the quantity too big", js: true do
        within ".distribution_line_items_quantity" do
          first("[data-quantity]").set 999_999
        end
        click_on "Save"
        click_button "Yes, it's correct"

        expect(page).to have_no_content "Distribution updated!"
        expect(page).to have_content(/Could not reduce quantity/i)
        expect(page).to have_content 999_899, count: 1
        within "[data-flash]" do
          expect(page).to have_content 999_899
        end
        expect(Distribution.first.line_items.count).to eq 1
      end

      it "User creates duplicate line items" do
        item = @distribution.line_items.first.item
        select2(page, 'distribution_line_items_item_id', item.name, position: 1)
        find_all("[data-quantity]")[0].set 1

        click_on "Add another item"

        select2(page, 'distribution_line_items_item_id', item.name, position: 2)
        new_select = find_all("[data-quantity]")[1]
        expect(new_select.value).to eq("")
        find_all("[data-quantity]")[1].set 3

        first("button", text: "Save").click
        click_button "Yes, it's correct"

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
      @request = create(:request, organization:, request_items:, partner:)
      create(:item_request, request: @request, item_id: items[0], quantity: 10)
      create(:item_request, request: @request, item_id: items[1], quantity: 10)

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
          expect(page).to have_content(ActiveSupport::NumberHelper.number_to_delimited(item["quantity"]))
        end
        click_button "Yes, it's correct"
      end

      expect(page).to have_content("Distribution complete")

      @request = Request.last
      @distribution = Distribution.last
      expect(@request.distribution_id).to eq @distribution.id
      expect(@request).to be_status_fulfilled
    end

    it "maintains the connection with the request even when there are initial errors" do
      items = storage_location.items.pluck(:id).sample(2)
      request_items = [{ "item_id" => items[0], "quantity" => 1000000 }, { "item_id" => items[1], "quantity" => 10 }]
      @request = create(:request, organization:, request_items:, partner:)
      create(:item_request, request: @request, item_id: items[0], quantity: 1000000)
      create(:item_request, request: @request, item_id: items[1], quantity: 10)

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
          expect(page).to have_content(ActiveSupport::NumberHelper.number_to_delimited(item["quantity"]))
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

      expect(page).to have_content("Distribution complete")

      @request = Request.last
      @distribution = Distribution.last
      expect(@request.distribution_id).to eq @distribution.id
      expect(@request).to be_status_fulfilled
    end
  end

  context "via barcode entry" do
    let(:existing_barcode) { create(:barcode_item, quantity: 50) }
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

        within "dialog[open]" do
          page.fill_in "Quantity", with: "51"
          open_filters
          select "VerySpecificItem", from: "Item"
          click_on "Save"
        end

        visit new_distribution_path
        Barcode.boop(barcode_value)

        expect(page).to have_text("VerySpecificItem")
        # By id, not by the label "Quantity": the row's quantity control has no visible label any
        # more -- the column heading carries the word and the control carries it as an aria-label,
        # which Capybara does not match unless enable_aria_label is on. Matching by text here found
        # the barcode dialog's own Quantity field instead.
        expect(page).to have_field("distribution_line_items_attributes_0_quantity", with: "51")
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
      open_filters
      select(item1.name, from: "filters[by_item_id]")
      wait_for_filters
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
        open_filters
        select(item_category.name, from: "filters[by_item_category_id]")
        wait_for_filters
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
      open_filters
      select(partner1.name, from: "filters[by_partner]")
      wait_for_filters
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
      open_filters
      select(distribution1.state.humanize, from: "filters[by_state]")
      wait_for_filters
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

    open_filters
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

    click_link "Make a correction"

    fill_in "distribution_line_items_attributes_0_quantity", with: 20

    click_button "Save"
    # The confirmation runs on every save, including a correction. On main it never appeared
    # at all: the controller called Bootstrap's $(el).modal("show") inside a promise, which
    # threw, and the catch submitted the form.
    click_button "Yes, it's correct"

    expect(page).to have_content("Distribution complete")
    expect(page).to have_button("Distribution complete")

    expect(View::Inventory.new(organization.id)
      .quantity_for(item_id: item.id, storage_location: storage_location.id)).to eq(0)

    click_button "Distribution complete"
    expect(page).to have_content('Distribution')

    expect(page).to have_content("This distribution has been marked as being completed!")
  end

  it "Double clicking distribution complete does not result in the distribution attemping to be completed twice" do
    visit new_distribution_path
    item = View::Inventory.new(organization.id).items_for_location(storage_location.id).first.db_item
    TestInventory.create_inventory(organization,
      {
        storage_location.id => { item.id => 20 }
      })

    open_filters
    select "Test Partner", from: "Partner"
    select "Test Storage Location", from: "From storage location"
    choose "Delivery"
    select item.name, from: "distribution_line_items_attributes_0_item_id"
    fill_in "distribution_line_items_attributes_0_quantity", with: 15

    click_button "Save"

    within "#distributionConfirmationModal" do
      click_button "Yes, it's correct"
    end

    expect(page).to have_content("Distribution created!")

    # Make sure the button is there before trying to double click it
    expect(page).to have_button("Distribution complete", visible: true)

    # Double click on the Distribution Complete button
    ferrum_double_click("form[action='#{distribution_path(id: organization.distributions.last.id)}/picked_up']")

    expect(page).to have_content("This distribution has been marked as being completed!")
    expect(page).not_to have_button("Distribution complete")

    # If it tries to mark the distribution as completed twice, the second time
    # will fail (the distribution is already complete) and show this error
    expect(page).not_to have_content("Sorry, we encountered an error when trying to mark this distribution as being completed")
  end

  describe "CSV export", js: true do
    before do
      create(:distribution, :with_items, organization: organization)
      visit distributions_path
    end

    # "Export", not main's "Export Distributions": every index page in this app labels it the same
    # way. And the notice arrives in the flash strip rather than a toastr pop-up, which could not
    # come across -- the essentials layouts load only tailwind.css, so toastr has no styling here.
    it "downloads a CSV and says so" do
      click_on "Export"

      wait_for_download
      expect(downloads.length).to eq(1)
      expect(download).to match(/Distributions.*\.csv/)
      expect(page).to have_css("[data-flash]", text: "Your CSV export is downloading.")
    end
  end
end
