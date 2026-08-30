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
    # last row. The panel is placed against the viewport instead -- and, since the actions column
    # became a `position: sticky` cell, it is also moved to `<body>` while open: `fixed` escapes an
    # ancestor's overflow but not its stacking context, and trapped in that cell the open menu sat
    # underneath the scroll rail. See popover_controller.
    it "escapes the table's scroll region, and its stacking context" do
      # The id is read while the menu is open: moving the node makes Capybara's reference stale,
      # so the string has to be captured before the panel goes home.
      panel_id = open_row_menu(row: "Costco")[:id]

      expect(page.evaluate_script(
        "getComputedStyle(document.getElementById(#{panel_id.to_json})).position"
      )).to eq("fixed")
      expect(page.evaluate_script(
        "document.getElementById(#{panel_id.to_json}).parentElement.tagName"
      )).to eq("BODY")

      # And back where it belongs once it closes, so Turbo replacing the row does not strand it.
      page.send_keys(:escape)
      expect(page).to have_no_css("[data-popover-target=panel]", visible: true)
      # That it goes *home* again is asserted in row_actions_reach_system_spec, on a page with no
      # filter frame: this one is inside a turbo-frame that may replace the table underneath the
      # assertion, which is a race rather than a fact about the portal.
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

  # The first version of this faded the *frozen* column, which does not move. Sampling the painted
  # pixels of the ID cell put it at 3.19:1 against white -- a 1.4.3 failure on the one column that
  # pinning exists to keep readable. Six of the seven tables that overflow have a frozen column.
  #
  # The second version put a shadow on the frozen cell instead, and that never painted at all: the
  # table is `border-collapse: collapse`, under which a box-shadow on a `td` is simply not drawn.
  # The spec for it passed anyway, because it read `getComputedStyle`, which reports the value
  # whether or not a pixel changes. So this asserts the arrangement that replaced it -- the shadow
  # is on the wrapper, and starts where the frozen column ends.
  it "starts the shadow where the frozen column ends, not on top of it" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-scroll[data-pinned]")

    page.execute_script(
      "document.querySelector('.table-scroll').scrollLeft = " \
      "document.querySelector('.table-scroll').scrollWidth"
    )
    expect(page).to have_css(".table-scroll[data-overflow~='start']")

    offset = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-scroll').parentElement, '::before').left"
    )
    pin_width = page.evaluate_script(
      "Math.round(document.querySelector('.table-scroll thead .pin-col').getBoundingClientRect().width)"
    )
    expect(offset).to eq("#{pin_width}px")
    expect(pin_width).to be > 0
  end

  # A box-shadow on a `td` is never painted under `border-collapse: collapse`, so the divider that
  # separates the frozen column from what scrolls under it has to be a real border.
  it "draws the frozen column's divider with a border, which paints" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    border = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-scroll tbody .pin-col')).borderRightWidth"
    )
    expect(border).to eq("1px")

    shadow = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-scroll tbody .pin-col')).boxShadow"
    )
    expect(shadow).to eq("none")
  end

  # The edge signal only ever says "there is more". The rail is the part you can act on: the
  # platform's scrollbar is an overlay taking 0px, and on five of the seven overflowing tables it is
  # below the fold anyway -- 296px below on /distributions.
  it "draws a rail for a table that overflows, and none for one that fits" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-rail[data-visible]")

    # Hidden from assistive technology exactly as a native scrollbar is: the region is already a
    # focusable named role="region" that the arrow keys scroll, so a second tab stop would duplicate
    # a path that already works.
    expect(page).to have_css(".table-rail[aria-hidden='true']")

    create(:vendor, organization: organization, business_name: "Costco")
    visit vendors_path
    expect(page).to have_no_css(".table-rail")
  end

  it "scrolls the table when the rail is dragged" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-rail[data-visible]")
    expect(page).to have_css(".table-scroll[data-overflow='end']")

    # Driven through the driver's mouse rather than `drag_to`: the rail listens for pointer events,
    # which is what a browser sends first for mouse, touch and pen alike, and Capybara's drag helper
    # does not reach them.
    box = page.evaluate_script(
      "(function () { var r = document.querySelector('.table-rail-thumb').getBoundingClientRect();" \
      " return [r.left + r.width / 2, r.top + r.height / 2]; })()"
    )
    page.driver.browser.mouse.move(x: box[0], y: box[1])
    page.driver.browser.mouse.down
    page.driver.browser.mouse.move(x: box[0] + 200, y: box[1])
    page.driver.browser.mouse.up

    # The table has moved, so the far edge is no longer the only one with content behind it.
    expect(page).to have_css(".table-scroll[data-overflow~='start']")
    expect(page.evaluate_script("document.querySelector('.table-scroll').scrollLeft")).to be > 0
  end

  # The track is the target, and 2.5.8 asks for 24px.
  it "gives the rail a target big enough to hit" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-rail[data-visible]")
    height = page.evaluate_script(
      "document.querySelector('.table-rail-track').getBoundingClientRect().height"
    )
    expect(height).to be >= 24
  end

  # `border-radius: var(--radius-full)` was set on both the track and the thumb, and --radius-full is
  # not a Tailwind v4 token -- the scale stops at --radius-2xl and `rounded-full` compiles to a
  # literal. The declaration was invalid, the browser dropped it, and the rail rendered as sharp
  # rectangles for weeks without anything noticing, because a var() naming a token that does not
  # exist fails silently. Assert the computed value, which is the only thing that would have caught
  # it.
  it "draws the track and the thumb as pills, not rectangles" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-rail[data-visible]")
    radii = page.evaluate_script(<<~JS)
      [
        getComputedStyle(document.querySelector('.table-rail-thumb')).borderRadius,
        getComputedStyle(document.querySelector('.table-rail-track'), '::before').borderRadius
      ].map(parseFloat)
    JS

    expect(radii).to all(be > 100)
  end

  # The rail has two states: riding the fold, where it lies over live rows and needs a backdrop to be
  # read against them, and settled in the card's reserved strip, where nothing is behind it and a
  # backdrop only washes out the card. Taking the backdrop off both is what was reported as "it
  # hovers in an odd way".
  it "carries a backdrop only while it floats over the table" do
    create_list(:distribution, 20, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-rail[data-visible]")

    page.execute_script("window.scrollTo(0, 0)")
    expect(page).to have_css(".table-rail[data-floating]")
    floating_background = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-rail')).backgroundColor"
    )
    expect(floating_background).not_to eq("rgba(0, 0, 0, 0)")

    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
    expect(page).to have_no_css(".table-rail[data-floating]")
    settled_background = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-rail')).backgroundColor"
    )
    expect(settled_background).to eq("rgba(0, 0, 0, 0)")
  end

  # The pager sits between the bar and the foot of the card, and wants the same air on both sides.
  # Measured in *boxes*, not in the strip's height: the rail carries 9px of dead space under a
  # centred bar for 2.5.8, so the strip alone never described what anyone was looking at. This has
  # been reported three times -- 0.14px, then 8px, then 30px too much -- so it is asserted as the
  # symmetry it actually is rather than as a magic number.
  it "gives the pager the same air above it as below it" do
    create_list(:distribution, 20, organization: organization)
    visit distributions_path

    expect(page).to have_css(".table-rail[data-visible]")
    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
    expect(page).to have_no_css(".table-rail[data-floating]")

    gaps = page.evaluate_script(<<~JS)
      (() => {
        const region = document.querySelector('.table-scroll');
        const footer = region.parentElement.nextElementSibling;
        const thumb = document.querySelector('.table-rail-thumb');
        const controls = [...footer.querySelectorAll('a, button, input, select')];
        const top = Math.min(...controls.map((c) => c.getBoundingClientRect().top));
        const bottom = Math.max(...controls.map((c) => c.getBoundingClientRect().bottom));
        return {
          above: top - thumb.getBoundingClientRect().bottom,
          below: footer.getBoundingClientRect().bottom - bottom,
          clearance: top - document.querySelector('.table-rail').getBoundingClientRect().bottom
        };
      })()
    JS

    expect(gaps["above"]).to be_within(3).of(gaps["below"])

    # And the rail's own box -- the 24px pointer target, not the 6px bar -- must stay off the pager's
    # controls, or a click meant for "Next" jumps the table sideways instead.
    expect(gaps["clearance"]).to be > 4
  end

  # One boundary gets one line. The bar is a heavier line than the footer's hairline, so where the
  # rail has settled the footer does not draw its own -- the same call `_pagination` already made
  # when drawing its own border put the pager inside two hairlines twelve pixels apart.
  it "drops the footer's rule where the rail has settled above it, and keeps it otherwise" do
    create_list(:distribution, 20, organization: organization)
    visit distributions_path

    border = lambda do
      page.evaluate_script(<<~JS)
        (() => {
          const region = document.querySelector('.table-scroll');
          const footer = region.parentElement.nextElementSibling;
          return footer ? getComputedStyle(footer).borderTopColor : null;
        })()
      JS
    end

    expect(page).to have_css(".table-rail[data-visible]")

    # Riding the fold, the bar is not above the footer, so the footer keeps its own rule. The footer
    # is off screen here, which is why the swap is never seen happening.
    page.execute_script("window.scrollTo(0, 0)")
    expect(page).to have_css("[data-railed='floating']")
    expect(border.call).not_to eq("rgba(0, 0, 0, 0)")

    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
    expect(page).to have_css("[data-railed='settled']")
    expect(border.call).to eq("rgba(0, 0, 0, 0)")
  end

  # A table that does not overflow has no bar to act as the separator, so nothing may touch its
  # footer. `/adjustments` fits at this width.
  it "leaves the footer's rule alone on a table with no rail" do
    create(:adjustment, organization: organization,
      storage_location: create(:storage_location, organization: organization))
    visit adjustments_path

    expect(page).to have_no_css(".table-rail")
    colour = page.evaluate_script(<<~JS)
      (() => {
        const region = document.querySelector('.table-scroll');
        const footer = region.parentElement.nextElementSibling;
        return footer ? getComputedStyle(footer).borderTopColor : 'no footer';
      })()
    JS

    expect(colour).not_to eq("rgba(0, 0, 0, 0)")
  end

  # Every table in the app scrolled sideways at 320px and at 375 before this: 15 of 15, the worst
  # hiding 80% of its width. A table too narrow to be a table becomes a list of labelled fields.
  context "when the container is too narrow to be a table" do
    before { create_list(:purchase, 2, organization: organization) }

    it "stacks into labelled fields with nothing off screen" do
      page.driver.resize(360, 800)
      visit purchases_path

      expect(page).to have_css("table.data-table[data-stack='1']")

      # The heading row is gone, so each field carries its own label instead. Matched in capitals
      # because Capybara compares rendered text and the label is uppercased by CSS -- the DOM text,
      # which is what a screen reader reads, is still sentence case.
      expect(page).to have_css(".cell-label", text: "STORAGE LOCATION")
      expect(page).to have_css(".cell-label", text: "AMOUNT SPENT")

      sideways = page.evaluate_script(
        "document.documentElement.scrollWidth > window.innerWidth + 1"
      )
      expect(sideways).to be false
    end

    # Changing `display` on a table drops rows and cells out of the accessibility tree, and the
    # header row is `display: none` here, so a screen reader would be left with bare text.
    it "keeps the table's semantics when it stops looking like a table" do
      page.driver.resize(360, 800)
      visit purchases_path

      expect(page).to have_css("table.data-table[data-stack]")
      expect(page).to have_css("table[role='table']")
      expect(page).to have_css("tbody[role='rowgroup']")
      expect(page).to have_css("tbody tr[role='row']")
      expect(page).to have_css("tbody td[role='cell']")
    end

    # A stacked table does not scroll, so the region must stop saying that it does.
    it "stops claiming to be a scrollable region" do
      page.driver.resize(360, 800)
      visit purchases_path

      expect(page).to have_css("table.data-table[data-stack]")
      expect(page).to have_no_css(".table-scroll[tabindex]")
      expect(page).to have_no_css(".table-rail")
    end

    it "goes back to being a table when there is room, and hides the labels again" do
      page.driver.resize(1200, 800)
      visit purchases_path

      expect(page).to have_css("table.data-table:not([data-stack])")
      expect(page).to have_css(".table-scroll[tabindex='0']")

      hidden = page.evaluate_script(
        "getComputedStyle(document.querySelector('.cell-label')).display"
      )
      expect(hidden).to eq("none")
    end

    # 640px of window leaves about 590px of card, which is inside the two-column band. A 700px
    # window leaves roughly 650 and is over the threshold, so the table stays a table.
    it "gives the fields two columns when the card is wide enough for two" do
      page.driver.resize(640, 800)
      visit purchases_path

      expect(page).to have_css("table.data-table[data-stack='2']")
    end
  end

  # Where nothing is frozen there is nothing to protect, so the fade belongs at the edge after all.
  it "keeps the start fade on a table with no frozen column" do
    create(:item, organization: organization, name: "Toddler nappies")
    visit items_path

    expect(page).to have_css(".table-scroll:not([data-pinned])")

    page.execute_script(
      "document.querySelector('.table-scroll').scrollLeft = " \
      "document.querySelector('.table-scroll').scrollWidth"
    )

    expect(page).to have_css(".table-scroll[data-overflow~='start']")
    start_shadow = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-scroll').parentElement, '::before').opacity"
    )
    expect(start_shadow).to eq("1")

    # Nothing frozen, so it starts at the container's own edge.
    offset = page.evaluate_script(
      "getComputedStyle(document.querySelector('.table-scroll').parentElement, '::before').left"
    )
    expect(offset).to eq("0px")
  end
end
