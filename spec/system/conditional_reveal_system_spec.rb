# The conditional reveal pattern, checked in a browser because every claim it makes is about
# geometry or computed style -- none of it is visible to a request spec.
#
# Reported on /distributions/new: "the location and size of the shipping cost field does not make
# any sense... shouldn't it be below the shipping cost radio button?" It was 529px where every
# other field on the card is 346px, in a second grid beside the radios, and 94px *above* the
# option that produces it.
#
# See "Conditional reveal" in design.md. `bin/design/disclosure-audit.js` checks every reveal in
# the app; this pins the one that was reported, so a regression fails the suite rather than
# waiting for someone to run the audit.
RSpec.describe "Conditional reveal", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  # Rounded, because a fractional grid column puts sub-pixel values in these.
  def box(selector)
    page.evaluate_script(
      "(() => { const r = document.querySelector(#{selector.to_json}).getBoundingClientRect(); " \
      "return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width) }; })()"
    ).symbolize_keys
  end

  def style(selector, property)
    page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
  end

  describe "the shipping cost field on a new distribution" do
    before { visit new_distribution_path }

    it "is rendered hidden by the server, not hidden by the controller after paint" do
      # The class is in the markup. If the controller were still doing this on connect(), the
      # field would be painted first and flash -- reported as "a ghost button that appears for a
      # second when you click refresh".
      expect(page).to have_css("#shipping_cost_div.hidden", visible: :hidden)
    end

    it "appears below the option that reveals it, never beside it" do
      choose "Shipped"

      radio = box("#distribution_delivery_method_shipped")
      reveal = box("#shipping_cost_div")

      expect(reveal[:y]).to be > radio[:y]
      # 6px in from the radio's own left edge, which is what centres a 4px rule under a 16px
      # control. It used to sit 549px to the right, in a grid of its own.
      expect(reveal[:x] - radio[:x]).to eq(6)
    end

    it "lines its field up with the label of the option it belongs to" do
      choose "Shipped"

      expect(box("#distribution_shipping_cost")[:x])
        .to eq(box("label[for='distribution_delivery_method_shipped']")[:x])
    end

    it "takes its width from the grid column rather than a second, wider grid" do
      choose "Shipped"

      # One column of `lg:grid-cols-3`, less the 24px indent. It was 529px against every other
      # field's 346px before this.
      column = box("#distribution_agency_rep")[:w]
      expect(box("#distribution_shipping_cost")[:w]).to eq(column - 24)
    end

    it "carries the indent and the rule that say which option owns it" do
      expect(style("#shipping_cost_div", "borderLeftWidth")).to eq("4px")
      expect(style("#shipping_cost_div", "marginLeft")).to eq("6px")
      expect(style("#shipping_cost_div", "paddingLeft")).to eq("14px")
    end

    it "points at the revealed field from the trigger, and claims nothing ARIA disallows" do
      radio = find("#distribution_delivery_method_shipped", visible: :all)

      expect(radio["aria-controls"]).to eq("shipping_cost_div")
      # aria-expanded is not allowed on role=radio: measured with axe, adding it to these three
      # raises aria-allowed-attr x3. govuk-frontend ships it; we do not.
      expect(radio["aria-expanded"]).to be_nil
    end

    it "still reveals and re-hides as the delivery method changes" do
      choose "Shipped"
      expect(page).to have_css("#shipping_cost_div", visible: :visible)

      choose "Pick up"
      expect(page).to have_css("#shipping_cost_div.hidden", visible: :hidden)
    end
  end

  describe "a reveal whose content already carries its own box" do
    before { visit new_partner_path }

    it "is positioned under its trigger but not indented or ruled" do
      # A callout is already a distinct tinted block; an indent and a rule on top of that would
      # mark one relationship twice. The component says which kind it is so the audit can tell.
      expect(find("#partner_reminder_note", visible: :all)["data-conditional-reveal"]).to eq("plain")
      expect(style("#partner_reminder_note", "borderLeftWidth")).to eq("0px")
    end

    it "can actually be revealed -- the Stimulus target used to be unreachable" do
      # The target was handed to the callout as `data:`, which the partial splatted at the top
      # level, so it rendered as a literal `checkbox_with_nested_element_target` attribute.
      # Stimulus threw "Missing target element" on connect and on every click, and this callout
      # could never appear.
      expect(page).to have_css("#partner_reminder_note.hidden", visible: :hidden)

      check "send_reminders"
      expect(page).to have_css("#partner_reminder_note", visible: :visible,
        text: "Reminders are sent according to the settings")
    end
  end
end
