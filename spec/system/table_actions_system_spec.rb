RSpec.describe "Table actions", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  before { sign_in(organization_admin) }

  # Four variants existed across 43 tables: 33 hidden and plural, 8 visible, one `<th>Action` with
  # no scope and no alignment, one hidden and singular.
  describe "the actions column header" do
    # A row each, or the page renders its empty state and there is no table to check.
    before do
      create(:item, organization: organization)
      create(:partner, organization: organization)
      create(:donation_site, organization: organization)
      create(:vendor, organization: organization)
    end

    it "is visible, scoped and right-aligned on every table" do
      %w[/items /partners /donation_sites /vendors].each do |path|
        visit path
        header = page.evaluate_script(<<~JS)
          (() => {
            const ths = [...document.querySelectorAll("table.data-table thead th")];
            const last = ths[ths.length - 1];
            return { text: last.textContent.trim(), scope: last.getAttribute("scope"),
                     align: getComputedStyle(last).textAlign,
                     srOnly: !!last.querySelector(".sr-only") };
          })()
        JS
        expect(header["text"]).to eq("Actions"), "#{path} header is #{header["text"].inspect}"
        expect(header["scope"]).to eq("col"), "#{path} header has no scope"
        expect(header["align"]).to eq("right")
        expect(header["srOnly"]).to be(false), "#{path} still hides its header"
      end
    end
  end

  # The reason an action is unavailable used to be sr-only: a screen reader heard it and a sighted
  # user saw a greyed-out word and nothing else. Reported as confusing, and it was.
  describe "an action that is unavailable" do
    let!(:item) { create(:item, organization: organization, name: "Held item") }

    before do
      TestInventory.create_inventory(organization,
        create(:storage_location, organization: organization).id => [[item.id, 5]])
      visit items_path
    end

    it "says why, in text anyone can read" do
      menu = open_row_menu(row: "Held item")

      expect(menu).to have_button("Deactivate", disabled: true)
      expect(menu).to have_text("Still in inventory or used by a kit")

      reason = page.evaluate_script(<<~JS)
        (() => {
          const panel = document.querySelector("[data-popover-target=panel]:not([hidden])");
          const btn = panel.querySelector("button[disabled]");
          const help = btn.querySelector("span span:last-child");
          if (!help) return null;
          // every opacity between the reason and the document -- `opacity-60` on the whole item
          // painted it at 2.32:1, and the point of showing a reason is that it gets read.
          const chain = [];
          let n = help;
          while (n && n !== document.documentElement) {
            const o = getComputedStyle(n).opacity;
            if (o !== "1") chain.push(o);
            n = n.parentElement;
          }
          return { text: help.textContent.trim(), srOnly: help.className.includes("sr-only"),
                   visible: help.offsetParent !== null, dimmedBy: chain,
                   colour: getComputedStyle(help).color };
        })()
      JS

      expect(reason).not_to be_nil
      expect(reason["srOnly"]).to be(false)
      expect(reason["visible"]).to be(true)
      expect(reason["dimmedBy"]).to be_empty
      # Still in the accessible name, so nothing was taken from a screen reader to give to the eye.
      expect(page.evaluate_script(<<~JS)).to include("Still in inventory")
        document.querySelector("[data-popover-target=panel]:not([hidden]) button[disabled]")
          .textContent.replace(/\\s+/g, " ").trim()
      JS
    end
  end
end
