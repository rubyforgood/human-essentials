RSpec.describe "Clipped table text", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  let(:long_comment) do
    "Picked up from the Tuesday drive at the community centre; two pallets were short " \
      "so the remainder is expected next week. Invoice sent to finance on the 14th."
  end

  # The tooltip is the second half of the `.notes` pattern: the column clips free text so the
  # table stays scannable, and this gives the clipped text back on demand. See design.md.
  context "when a comment is too long for its column" do
    before do
      create(:purchase, organization: organization, comment: long_comment)
      visit purchases_path
    end

    it "marks the cell as clipped and lets it take focus" do
      cell = find("td.notes[data-clipped]", match: :first)
      expect(cell[:tabindex]).to eq("0")
    end

    it "shows the whole comment on hover and hides it again" do
      find("td.notes[data-clipped]", match: :first).hover
      expect(page).to have_css(".tip-bubble", text: "Invoice sent to finance")

      # Moving away closes it. `find("h1").hover` is a real pointer move, not a synthetic event.
      find("h1").hover
      expect(page).to have_no_css(".tip-bubble")
    end

    it "shows it on keyboard focus and dismisses it with Escape" do
      page.execute_script("document.querySelector('td.notes[data-clipped]').focus()")
      expect(page).to have_css(".tip-bubble")

      page.send_keys(:escape)
      expect(page).to have_no_css(".tip-bubble")
    end

    it "does not describe the cell with a copy of its own text" do
      # The full string is already in the DOM, so a screen reader has read it. Describing the
      # cell with the same words would announce it twice -- the main fault of `title`.
      find("td.notes[data-clipped]", match: :first).hover
      expect(page).to have_css(".tip-bubble[aria-hidden='true']")
      expect(page).to have_no_css("td.notes[aria-describedby]")
    end
  end

  # The controller keys on any overflowing cell, not on `.notes`. It was scoped to that class at
  # first, which meant capping a second kind of column produced text nobody could read.
  context "when a name is too long for its capped column" do
    let(:long_name) { "Greater Metropolitan Area Family Support and Diaper Assistance Coalition" }

    before do
      create(:vendor, organization: organization, business_name: long_name)
      visit vendors_path
    end

    it "clips the name and reveals it on hover" do
      cell = find("td.name[data-clipped]", match: :first)
      expect(cell[:tabindex]).to eq("0")

      cell.hover
      expect(page).to have_css(".tip-bubble", text: "Diaper Assistance Coalition")
    end

    # The focus ring was keyed on `td.notes[data-clipped]` while the controller marked any cell, so
    # a capped name was focusable with the browser's 1px default instead of the brand ring.
    it "gets the app's focus ring, not the browser's default" do
      page.execute_script("document.querySelector('td.name[data-clipped]').focus()")
      ring = page.evaluate_script(
        "getComputedStyle(document.querySelector('td.name[data-clipped]')).outlineWidth"
      )
      expect(ring).to eq("2px")
    end

    # `cursor: help` put a question mark over a partner's name. The ellipsis is the affordance.
    it "does not change the cursor" do
      cursor = page.evaluate_script(
        "getComputedStyle(document.querySelector('td.name[data-clipped]')).cursor"
      )
      expect(cursor).to eq("auto")
    end
  end

  context "when a comment fits" do
    before do
      create(:purchase, organization: organization, comment: "Short.")
      visit purchases_path
    end

    it "adds no tooltip and no tab stop" do
      expect(page).to have_css("td.notes")
      expect(page).to have_no_css("td.notes[data-clipped]")
      expect(page).to have_no_css("td.notes[tabindex]")
    end
  end
end

RSpec.describe "Row action menus", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  # Five labelled buttons made the actions column 331px on /distributions -- see design.md.
  context "on a table with several row actions" do
    before do
      create(:vendor, organization: organization, business_name: "Costco")
      visit vendors_path
    end

    it "names the trigger after its row, so a screen reader does not hear 'button' once per row" do
      trigger = find("tbody tr [data-popover-target=trigger]", match: :first)
      expect(trigger["aria-label"]).to include("Costco")
      expect(trigger["aria-haspopup"]).to eq("true")
      expect(trigger["aria-expanded"]).to eq("false")
    end

    it "opens with focus on the first item" do
      panel = open_row_menu(row: "Costco")
      items = panel.all("[role=menuitem]")
      expect(items.size).to be >= 2
      expect(page.evaluate_script("document.activeElement.textContent.trim()")).to eq(items.first.text)
    end

    # Arrow-key movement and Escape-with-refocus are checked by `bin/design/overlay-audit.js`,
    # across all 90 popovers in the app rather than one. Cuprite would not deliver a key to the
    # focused node here -- neither `page.send_keys` nor `Element#send_keys` reached it, and the
    # first version of this spec passed for the wrong reason because focus had landed on a filter
    # input and "not the first item" was trivially true.

    # `.table-scroll` clips on both axes, so an absolutely positioned panel was cut off on the
    # last row. The panel is placed against the viewport instead.
    it "escapes the table's scroll region" do
      open_row_menu(row: "Costco")
      position = page.evaluate_script(
        "getComputedStyle(document.querySelector('tbody tr [data-popover-target=panel]')).position"
      )
      expect(position).to eq("fixed")
    end
  end
end

RSpec.describe "Scrolling tables say so", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  # A wide table may scroll -- Reflow exempts data tables -- but it has to admit it. Before this,
  # /distributions hid 486px of columns behind an overlay scrollbar taking 0px of height, with no
  # visual signal at all. See design.md.
  it "marks the edge that has content behind it, and only that edge" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    expect(page.evaluate_script("document.querySelector('.table-scroll').scrollWidth >" \
                                " document.querySelector('.table-scroll').clientWidth")).to be true
    # Matched with `have_css` rather than read off the node, so Capybara waits for the scroll
    # listener instead of racing it.
    expect(page).to have_css(".table-scroll[data-overflow='end']")

    page.execute_script(
      "document.querySelector('.table-scroll').scrollLeft = " \
      "document.querySelector('.table-scroll').scrollWidth"
    )
    expect(page).to have_css(".table-scroll[data-overflow='start']")
  end

  it "leaves a table that fits with no fade at all" do
    create(:vendor, organization: organization, business_name: "Costco")
    visit vendors_path

    # `evaluate_script` evaluates an expression, so no `const` -- it is a syntax error there.
    fits = page.evaluate_script("document.querySelector('.table-scroll').scrollWidth <=" \
                                " document.querySelector('.table-scroll').clientWidth + 1")
    expect(fits).to be true
    expect(page).to have_css(".table-scroll[data-overflow='']")
  end

  # The fade sits over the rightmost column, which on these tables holds the actions menu.
  it "never intercepts a click" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    pointer_events = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-scroll').parentElement, '::after').pointerEvents"
    )
    expect(pointer_events).to eq("none")
  end
end
