# The History page's row funnel, and the scroll rail underneath it.
#
# Reported together: "there is a filter button next to Refers to, it is not clear what happens when
# this is pressed and how to reverse this action ... the scroll bar is stuck on the item drop down
# ... why is there an icon button with no label or tooltip ... the alignment looks wrong."
#
# Four separate faults on one page. Each is pinned here, because each was invisible to the audits
# that were meant to catch it: the tooltip audit only read `.cell-actions`, and the rail's second
# copy only appeared after a Turbo frame swap.
RSpec.describe "History", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:organization_admin, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item) { create(:item, organization: organization, name: "Item1") }

  let!(:adjustment) do
    create(:adjustment, :with_items, storage_location: storage_location,
      organization: organization, item: item, item_quantity: 88)
  end

  before do
    donation = create(:donation, :with_items, storage_location: storage_location,
      organization: organization, item: item, item_quantity: 66)
    DonationEvent.publish(donation)
    AdjustmentEvent.publish(adjustment)

    sign_in user
    visit events_path
  end

  let(:label) { "Show only this record's history" }

  # Double quotes around the attribute value: the label has an apostrophe in it, and a single-quoted
  # CSS string ends at the first one -- Cuprite reports that as `InvalidSelector`, not as no match.
  def funnel
    find(%(td.cell-actions a[aria-label="#{label}"]), match: :first)
  end

  # The rows are most recent first, so which record row one belongs to is not something to assume.
  def funnel_for(record)
    find(%(td.cell-actions a[href*="eventable_type=#{record.class.name}"]) +
         %([href*="eventable_id=#{record.id}"]))
  end

  describe "the funnel on a row" do
    it "says what it does, on hover and to a screen reader" do
      # design.md: an icon-only control is named by `aria-label` AND `data-tooltip`, never `title`.
      # This one had the label and no tooltip, so there was nothing to hover and nothing to read.
      expect(funnel["data-tooltip"]).to eq(label)
      expect(funnel["aria-label"]).to eq(label)
      expect(funnel["title"]).to be_blank
    end

    it "is a row action in the actions column, at the size every other one is" do
      # It used to be a 34x30 ghost button inline in the "Refers to" cell, three pixels from the
      # record link, in the narrowest column of the table.
      box = page.evaluate_script(
        "(() => { const r = document.querySelector(\"td.cell-actions a\").getBoundingClientRect(); " \
        "return [Math.round(r.width), Math.round(r.height)]; })()"
      )
      expect(box).to eq([28, 28])
      expect(page).to have_css("table thead th.cell-actions", text: "Actions")
    end

    it "narrows the page, and says so with a chip that undoes it" do
      expect(page).to have_no_link("Clear all")

      funnel_for(adjustment).click

      # The narrowing is a filter like any other: counted, chipped, and reversible.
      expect(page).to have_css("[data-filter-summary-target='chips']", text: "Refers to")
      expect(page).to have_css("[data-filter-summary-target='chips']", text: "Adjustment #{adjustment.id}")
      expect(page).to have_link("Clear all")
      expect(page).to have_css("tbody tr", count: 1)

      find("[data-filter-summary-target='chips'] button").click

      expect(page).to have_css("tbody tr", minimum: 2)
      expect(page).to have_no_css("[data-filter-summary-target='chips'] button")
    end
  end

  it "leaves no scroll rail behind when a filter replaces the table" do
    # The rail is built once per scrollable region and kept in a Map keyed on it. Turbo swaps the
    # region out, `markAll` only ever visits regions still in the document, and so the old rail
    # stayed on the body -- fixed where it was, scrolling nothing. Two bars, one of them stuck.
    #
    # **It has to be the filter bar that applies it, not the row funnel.** The funnel is a plain
    # link and Turbo Drive is off app-wide, so clicking it reloads the page, the controller
    # disconnects and takes every rail with it -- which is why the first version of this example
    # passed with the sweep deleted. Only a submit into the results frame swaps a region out from
    # under a controller that stays connected, which is the situation the bug lives in.
    expect(page).to have_css("table")

    # One rail per overflowing table, and no others. Counting rails alone is not enough: the
    # filtered page holds a single row, which does not overflow, so a stale rail plus no live one
    # comes to the same total as one live rail and the example passes with the bug in place. The
    # invariant is what the controller actually promises.
    tally = lambda do
      page.evaluate_script(<<~JS)
        (() => {
          const regions = [...document.querySelectorAll(".table-scroll")]
            .filter((r) => r.scrollWidth - r.clientWidth > 1).length;
          return [regions, document.querySelectorAll(".table-rail").length];
        })()
      JS
    end

    # Vacuity guard: if nothing overflowed there would be no rail to strand in the first place.
    expect(tally.call).to eq([1, 1])

    rows_before = page.all("tbody tr").size

    find("[data-filter-toggle]").click
    select "Adjustment", from: "Event type"

    expect(page).to have_css("tbody tr", maximum: rows_before - 1)

    # A Capybara matcher, because it retries and `evaluate_script` does not. Two earlier versions of
    # this example tallied the rails with `evaluate_script` and passed with the sweep deleted: the
    # new rail is laid out on `turbo:frame-load`, which had not fired yet, so the script counted the
    # stranded rail alone and called it one. There is one table on this page, so one bar.
    expect(page).to have_css(".table-rail", maximum: 1, visible: :all)

    regions, rails = tally.call
    expect(rails).to eq(regions)
  end

  it "puts nothing in a `title`, which is not a tooltip" do
    # Every row's Type cell carried `title="Internal Event ID: N"`: browser chrome, silent on
    # keyboard focus, and an internal id a diaper bank has no use for.
    expect(page).to have_no_css("main [title]")
  end
end
