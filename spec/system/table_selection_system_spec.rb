# Selecting rows so several can be acted on at once.
#
# Freezing the actions column removed the *travel* to a row's actions; this removes the
# *repetition*. The shape is Carbon's `TableBatchActions`, which is also what Gmail, GitHub,
# Linear and Jira use. See design.md, Selection.
RSpec.describe "Selecting rows", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in user
    create_list(:request, 4, organization: organization)
    visit requests_path
  end

  def boxes
    all("[data-table-selection-target='row']")
  end

  it "shows nothing until something is selected, and says how many" do
    # Rendered hidden by the server and revealed by the controller: JavaScript may reveal, never
    # un-draw. See design.md.
    expect(page).to have_css("[data-table-selection-target='bar']", visible: :hidden)

    boxes.first.check

    expect(page).to have_css("[data-table-selection-target='bar']", visible: :visible)
    expect(page).to have_css("[data-table-selection-target='count']", text: "1 selected")
  end

  it "leaves the filters and the totals button reachable while a selection is live" do
    # They are not mutually exclusive. The first version replaced the filter row on the strength of
    # Carbon's TableBatchActions -- but Carbon is the only one of those systems that does that:
    # GitHub's batch header replaces a *list header* below its filters, and Gmail's action toolbar
    # is not its search bar. Reported as "the filter and the picklist action are not simultaneously
    # present... they should not be mutually exclusive".
    boxes.first.check

    expect(page).to have_css("[data-table-selection-target='bar']", visible: :visible)
    expect(page).to have_css("[data-filter-toggle]", visible: :visible)
    expect(page).to have_button("Show product totals", visible: :visible)
  end

  it "floats over the list rather than moving it" do
    # /requests is 1,289px against a 900px viewport, so a bar pinned to the top of the list scrolls
    # out of reach exactly when you have finished choosing. Linear, Notion, Airtable and Drive all
    # float one for that reason.
    head_y = lambda {
      page.evaluate_script(
        "Math.round(document.querySelector('main table.data-table thead').getBoundingClientRect().top + scrollY)"
      )
    }

    at_rest = head_y.call
    boxes.first.check

    expect(page).to have_css("[data-table-selection-target='bar']", visible: :visible)
    expect(head_y.call).to eq(at_rest)
    expect(page.evaluate_script(
      "getComputedStyle(document.querySelector(\"[data-table-selection-target='bar']\")).position"
    )).to eq("fixed")
  end

  it "keeps the totals button on the filter row, not in a band of its own" do
    # That band was 63px of card, rule and all, for one 30px button. The totals are "across every
    # request matching the current filters", so they belong beside the filters that decide them.
    expect(page).to have_css("main form[data-controller~='auto-submit']", text: "Show product totals")
  end

  it "extends a range with shift-click" do
    # Bound to `click`, not `change`: a change event carries no `shiftKey`, and the first version
    # selected the two ends of the range and nothing in between.
    boxes.first.check
    boxes.last.click(:shift)

    expect(page).to have_css("[data-table-selection-target='count']", text: "4 selected")
  end

  it "marks the header box indeterminate when only some are chosen" do
    boxes.first.check

    # `indeterminate` is a property rather than an attribute, so it can only be read from the DOM.
    # A checked select-all with one of four chosen would claim something untrue.
    expect(page.evaluate_script(
      "document.querySelector(\"[data-table-selection-target='all']\").indeterminate"
    )).to be(true)

    find("[data-table-selection-target='all']").check
    expect(page.evaluate_script(
      "document.querySelector(\"[data-table-selection-target='all']\").indeterminate"
    )).to be(false)
    expect(page).to have_css("[data-table-selection-target='count']", text: "4 selected")
  end

  it "clears with Escape, which is the way out that needs no aiming" do
    boxes.first.check
    expect(page).to have_css("[data-table-selection-target='bar']", visible: :visible)

    page.send_keys(:escape)

    expect(page).to have_css("[data-table-selection-target='bar']", visible: :hidden)
    expect(boxes.map(&:checked?)).to all(be(false))
  end

  it "puts the chosen ids on the batch action, so it is an ordinary link" do
    boxes.first.check

    href = find("[data-table-selection-target='action']")["href"]
    expect(href).to include("print_picklists")
    expect(href).to include("ids%5B%5D=")
  end

  it "freezes the selection column with the identifier rather than letting it scroll away" do
    # A checkbox you have to scroll back to find is no better than an action you have to scroll
    # forward to reach, which is the complaint this answers.
    page.execute_script("const w = document.querySelector('main .table-scroll'); w.scrollLeft = w.scrollWidth")
    sleep 0.3

    offsets = page.evaluate_script(<<~JS)
      (() => {
        const w = document.querySelector('main .table-scroll');
        const left = w.getBoundingClientRect().left;
        return {
          select: Math.round(document.querySelector('tbody .select-col').getBoundingClientRect().left - left),
          pin: Math.round(document.querySelector('tbody .pin-col').getBoundingClientRect().left - left)
        };
      })()
    JS

    expect(offsets["select"]).to eq(0)
    # The identifier starts where the checkbox ends, so the two behave as one frozen group.
    expect(offsets["pin"]).to be > 0
  end
end
