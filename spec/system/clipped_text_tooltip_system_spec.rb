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
