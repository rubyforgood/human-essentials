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
