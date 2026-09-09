RSpec.describe EssentialsUiHelper, type: :helper do
  # The validation guards one write path. This guards the *render*, for a row that arrived by
  # import, by console, or from a database restored from before the validation existed.
  describe "#essentials_safe_href" do
    it "returns an http(s) url unchanged" do
      expect(helper.essentials_safe_href("https://example.com")).to eq("https://example.com")
    end

    it "returns nil for a javascript: url" do
      expect(helper.essentials_safe_href("javascript:alert(1)")).to be_nil
    end

    it "returns nil for a dangerous url with a real one appended" do
      expect(helper.essentials_safe_href("javascript:alert(1) http://decoy.example.com")).to be_nil
    end

    it "returns nil for blank" do
      expect(helper.essentials_safe_href("")).to be_nil
      expect(helper.essentials_safe_href(nil)).to be_nil
    end
  end

  describe "#essentials_external_link" do
    it "links an http(s) url, with rel guarding the target" do
      html = Nokogiri::HTML(helper.essentials_external_link("https://example.com"))
      anchor = html.at_css("a")
      expect(anchor.attributes["href"].value).to eq("https://example.com")
      expect(anchor.attributes["rel"].value).to include("noopener")
    end

    # Not dropped: the reader should still see what the field holds, because a bank looking at a
    # nonsense URL is how it gets corrected.
    it "renders a dangerous url as text, with no anchor at all" do
      html = Nokogiri::HTML(helper.essentials_external_link("javascript:alert(1)"))
      expect(html.css("a")).to be_empty
      expect(html.at_css("span").text).to eq("javascript:alert(1)")
    end

    it "renders nothing for blank" do
      expect(helper.essentials_external_link("")).to be_nil
      expect(helper.essentials_external_link(nil)).to be_nil
    end
  end
end
