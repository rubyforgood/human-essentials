# Which glyph a button wears. See design.md -- "One glyph, one meaning" -- and the machine-readable
# copy of that table in bin/design/icon-lexicon.json, which this reads so the two cannot drift.
#
# The reported case was `/donation_sites`: **Import with an arrow leaving a tray and Export with one
# entering it**. Two frames of reference had collided. Upload/download is measured from the server
# -- up to it, down to you -- and import/export from the app -- in to it, out of it. The buttons
# used one vocabulary and the glyphs the other, so half the row read backwards whichever way you
# took it. Shopify Polaris and IBM Carbon both draw export as an arrow going up and out; Carbon
# ships `export` and `download` as separate icons, so it is explicit that an export is not a
# download.
#
# Asserted in a browser rather than by grepping the views, because the glyph on a page is not always
# in that page's template: `submit_button` put Font Awesome's `floppy-o` on twelve forms from a
# default argument, and no view mentioned it.
RSpec.describe "Button icons", type: :system, js: true do
  # Read, not restated: a copy of the table here would be one more thing to keep in step.
  lexicon = JSON.parse(Rails.root.join("bin/design/icon-lexicon.json").read).freeze
  known_glyphs = (lexicon["glyphs"].values + lexicon["structural"]).to_set.freeze
  generic_verbs = lexicon["generic_verbs"]["labels"].to_set.freeze

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  # Every button-ish control on the page, with its visible word and the glyphs inside it.
  def controls_on_page
    page.evaluate_script(<<~JS)
      [...document.querySelectorAll("a, button, input[type=submit]")]
        .filter((el) => el.classList.contains("inline-flex") && el.classList.contains("rounded-lg"))
        .map((el) => {
          const clone = el.cloneNode(true);
          clone.querySelectorAll(".sr-only").forEach((n) => n.remove());
          return {
            label: (clone.textContent || el.value || "").replace(/\\s+/g, " ").trim(),
            icons: [...el.querySelectorAll("i")].flatMap((i) => [...i.classList])
                     .filter((c) => c.startsWith("bi-"))
          };
        });
    JS
  end

  def glyphs_for(label)
    controls_on_page.select { |c| c["label"] == label }.flat_map { |c| c["icons"] }
  end

  describe "import and export" do
    before do
      create(:donation_site, organization: organization)
      visit donation_sites_path
    end

    it "points the import arrow into the box and the export arrow out of it" do
      expect(glyphs_for("Import donation sites")).to eq(["bi-box-arrow-in-down"])
      expect(glyphs_for("Export")).to eq(["bi-box-arrow-up"])
    end

    it "does not put an upload arrow on an import or a download arrow on an export" do
      # The exact inversion that was reported. `bi-upload` draws an arrow *leaving* a tray and
      # `bi-download` one entering it -- rasterised from the font to check, not read off the names.
      expect(glyphs_for("Import donation sites")).not_to include("bi-upload")
      expect(glyphs_for("Export")).not_to include("bi-download")
    end

    it "leaves bi-download meaning a download, on the same page" do
      # The import dialog offers a template file. That button really does download one, and it is
      # the reason export could not simply borrow the glyph.
      expect(glyphs_for("Download example CSV")).to eq(["bi-download"])
    end
  end

  describe "a generic form verb" do
    # "Save" says commit this form; it names no action, and there is exactly one submit on the
    # page, so a glyph beside it distinguishes it from nothing. It carried Font Awesome's
    # `floppy-o` on the twelve forms built through `submit_button` and nothing on the other
    # twenty-nine -- a floppy disk, for a thing most users have never handled.
    {
      "a form built with essentials_form_actions" => "/items/new",
      "a form built with the legacy submit_button" => "/partner_groups/new"
    }.each do |shape, path|
      it "carries no glyph on #{shape}" do
        visit path
        offenders = controls_on_page
          .select { |c| generic_verbs.include?(c["label"].downcase) && c["icons"].any? }
        expect(offenders).to be_empty,
          "generic verbs wearing a glyph: #{offenders.map { |c| "#{c["label"]} #{c["icons"].join(" ")}" }.join(", ")}"
      end
    end
  end

  describe "the lexicon" do
    # Rule 4 of bin/design/icon-audit.js, pinned on a handful of pages so CI catches a new one-off
    # glyph without needing the whole crawl. `Invite user` reached three pages wearing three
    # different glyphs because nothing said which one was right.
    %w[/items /donation_sites /partners /distributions].each do |path|
      it "uses only glyphs it names, on #{path}" do
        visit path
        strays = controls_on_page.flat_map { |c| c["icons"] }.uniq.reject { |g| known_glyphs.include?(g) }
        expect(strays).to be_empty,
          "#{strays.join(", ")} is not in bin/design/icon-lexicon.json -- add it there with the meaning it carries"
      end
    end
  end
end
