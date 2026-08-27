RSpec.describe "Creating a parner child", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:partner) { FactoryBot.create(:partner, organization: organization) }
  let(:partner_user) { partner.primary_user }
  let(:family) { create(:partners_family, guardian_first_name: "Main", guardian_last_name: "Family", partner: partner) }

  before do
    partner.update(status: :approved)
    login_as(partner_user)
    create(:item, name: "Item 1", organization: organization)
    create(:item, name: "Item 2", organization: organization)
  end

  # "Reset search" is inert until there is a search to reset -- the same shape as the calendar's
  # Today, and the same answer from design.md: drawn, and disabled while it leads nowhere. A link
  # cannot be `disabled`, so an unavailable one is a non-interactive <span>.
  describe "the Reset search button" do
    let!(:child) { create(:partners_child, family: family, first_name: "Zeraphina", last_name: "Quill") }

    it "is inert until something has been searched for" do
      visit partners_children_path

      expect(page).to have_css("#filterrific_reset span[aria-disabled='true']")
      expect(page).to have_no_css("#filterrific_reset a")
      # The reason travels with it rather than leaving the reader to guess.
      expect(page.find("#filterrific_reset").text).to include("no search to reset")
    end

    # Filterrific replaces only #filterrific_results over AJAX. Without re-rendering the button
    # beside it, this stayed dimmed and claiming there was no search while the list below it showed
    # a filtered one -- measured, typing cut 86 rows to 82 and the button never moved.
    it "comes back to life once a search is typed" do
      visit partners_children_path
      expect(page).to have_css("#filterrific_reset span[aria-disabled='true']")

      fill_in "filterrific_search_names", with: "Zeraphina"

      expect(page).to have_css("#filterrific_reset a", text: "Reset search")
      expect(page).to have_no_css("#filterrific_reset [aria-disabled='true']")
    end

    # An *unchecked* box is not a search. Without this, "0" read as a value and Reset offered itself
    # for a search nobody had made.
    it "does not count an unchecked box as a search" do
      visit "#{partners_children_path}?filterrific%5Bsearch_active%5D=0"

      expect(page).to have_css("#filterrific_reset span[aria-disabled='true']")
    end
  end

  describe "creating a child for a family" do
    it "creates a child with correct info" do
      visit new_partners_child_path(family_id: family.id)
      fill_in "First name", with: "Child First Name"
      fill_in "Last name", with: "Child Last Name"
      select "Other", from: "Race"
      fill_in "Agency child ID", with: "01234"
      fill_in "Comments", with: "Some Comment"

      select2(page, "requestable-items-container", "Item 2")
      select2(page, "requestable-items-container", "Item 1")

      click_button "Add child"

      expect(page).to have_text("Child was successfully created.")
      expect(page).to have_text("Child First Name")
      expect(page).to have_text("Child Last Name")
      expect(page).to have_text("01234")
      expect(page).to have_text("Some Comment")
      expect(page).to have_text(/Item 1, Item 2|Item 2, Item 1/) # order of items requested not guaranteed
    end
  end
end
