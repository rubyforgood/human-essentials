# Where a form's buttons go. See design.md -- "Where a button goes".
#
# The rule is about scope: a card groups related content, and the submit commits the whole form, so
# the action row sits *below* the card with no divider. Before this, 33 views drew it inside the
# card under a rule that -- being inside the card's 20px body padding -- stopped 21px short of both
# edges, the only rule in the app that did not reach the edges of what it divided.
#
# Asserted in a browser rather than by grepping the views, because the thing that can go wrong here
# is not a class name. Moving the row out means the form has to wrap the card instead of the other
# way round, and a form boundary in the wrong place puts fields outside the form that submits them
# -- which renders fine, greps fine, and quietly loses data. This app has done it twice before.
RSpec.describe "Form actions", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  # One single-card form and one multi-card form: the rule is the same for both, which is the point
  # of it. `/items/new` was the shape that had the divider; `/kits/new` already had none.
  {
    "a single-card form" => "/items/new",
    "a multi-card form" => "/kits/new"
  }.each do |shape, path|
    context "on #{shape}" do
      before { visit path }

      it "puts the submit below the card, inside the form, with no divider" do
        expect(page).to have_css("form")

        result = page.evaluate_script(<<~JS)
          (() => {
            const form = document.querySelector('main form');
            const submit = form.querySelector('button[type=submit], input[type=submit]');
            const row = submit.parentElement;
            const cs = getComputedStyle(row);
            return {
              inForm: submit.closest('form') === form,
              inCard: !!submit.closest('section.card-surface'),
              borderWidth: cs.borderTopWidth,
              borderStyle: cs.borderTopStyle,
              marginTop: cs.marginTop
            };
          })()
        JS

        expect(result["inForm"]).to be(true)
        expect(result["inCard"]).to be(false), "the action row is still inside the card"
        # No divider: either no width or no style counts as none drawn.
        expect(result["borderWidth"] == "0px" || result["borderStyle"] == "none").to be(true),
          "the action row still draws a divider (#{result["borderWidth"]} #{result["borderStyle"]})"
        expect(result["marginTop"]).to eq("24px")
      end

      # The reparse hazard, and the reason this is a system spec at all.
      it "leaves no field outside the form that submits it" do
        orphans = page.evaluate_script(<<~JS)
          [...document.querySelectorAll('main input:not([type=hidden]), main select, main textarea')]
            .filter((c) => !c.closest('form')).length
        JS

        expect(orphans).to eq(0)
      end
    end
  end

  # The caveat in design.md: a button whose scope *is* the card stays in the card. The line item
  # card's "Add another item" adds a row to that card, so it belongs to it and keeps the card
  # footer's full-bleed rule.
  it "leaves a card's own action inside the card" do
    visit "/donations/new"

    add_another = find("#__add_line_item")
    expect(add_another).to be_present

    inside = page.evaluate_script(
      "!!document.querySelector('#__add_line_item').closest('section.card-surface')"
    )
    expect(inside).to be(true)
  end
end
