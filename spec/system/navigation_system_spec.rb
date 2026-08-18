RSpec.describe "Navigation", type: :system, js: true do
  # The AdminLTE rail was a flat list with a "collapse to icons" toggle. The design system rail
  # groups 34 bank destinations under four headings, and the mobile drawer replaces the
  # collapse toggle -- a rail that shrinks to unlabelled icons is not an accessibility win, it
  # just moves the labels into tooltips.
  #
  # These assert what the navigation is FOR: the destinations are reachable, a group opens,
  # and the group button says whether it is open.
  let(:sidebar) { page.find("#essentials-sidebar") }

  describe "bank sidebar" do
    before do
      sign_in(user)
      visit "/"
    end

    context "with organization admin" do
      let(:user) { create(:organization_admin) }

      it "shows the top-level destinations" do
        expect(sidebar).to have_link("Dashboard")
        expect(sidebar).to have_link("My organization")
      end

      it "groups the rest of the destinations" do
        # The group labels are upper-cased by CSS, so Capybara sees "OPERATIONS": match the
        # word, not the casing the stylesheet happens to apply.
        ["Operations", "Inventory", "Network", "Reporting"].each do |group|
          expect(sidebar).to have_css("button", text: /#{group}/i)
        end
      end

      describe "a collapsed group" do
        it "says it is collapsed, and opens on click" do
          button = sidebar.find("button", text: /inventory/i)
          expect(button["aria-expanded"]).to eq("false")

          button.click

          expect(button["aria-expanded"]).to eq("true")
          expect(sidebar).to have_link("Inventory audit")
          expect(sidebar).to have_link("Storage locations")
        end
      end

      describe "the Operations group" do
        before { sidebar.find("button", text: /operations/i).click }

        it "shows its destinations" do
          ["Donations", "Purchases", "Requests", "Distributions", "Pick ups & deliveries"].each do |title|
            expect(sidebar).to have_link(title)
          end
        end
      end

      describe "the Network group" do
        before { sidebar.find("button", text: /network/i).click }

        it "shows its destinations" do
          expect(sidebar).to have_link("Partner agencies")
          expect(sidebar).to have_link("Donation sites")
        end
      end

      describe "the Reporting group" do
        before { sidebar.find("button", text: /reporting/i).click }

        it "shows its destinations" do
          expect(sidebar).to have_link("Annual survey")
          expect(sidebar).to have_link("Distributions — by county")
        end
      end

      it "opens the group holding the current page" do
        visit storage_locations_path
        expect(sidebar.find("button", text: /inventory/i)["aria-expanded"]).to eq("true")
      end
    end

    context "with an organization user" do
      let(:user) { create(:user) }

      it "does not offer the admin-only destinations" do
        sidebar.find("button", text: /inventory/i).click
        expect(sidebar).to have_link("Storage locations")
        expect(sidebar).to have_no_link("Inventory audit")
        expect(sidebar).to have_no_link("My organization")
      end
    end
  end

  describe "admin sidebar" do
    before do
      sign_in(user)
      visit "/admin"
    end

    context "with superadmin user" do
      let(:user) { create(:super_admin) }

      it "replaces the bank destinations with the admin ones" do
        ["Admin dashboard", "Account requests", "Organizations", "NDBN member upload",
          "Partners", "Users", "Base items", "Barcode items", "Announcements", "FAQ"].each do |title|
          expect(sidebar).to have_link(title)
        end

        expect(sidebar).to have_no_css("button", text: /operations/i)
      end

      it "offers a way back out of the admin area" do
        expect(sidebar).to have_link("Leave admin")
      end
    end
  end
end
