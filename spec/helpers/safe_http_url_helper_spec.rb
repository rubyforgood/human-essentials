RSpec.describe ApplicationHelper, type: :helper do
  # The render half of the stored-XSS fix, kept out of the design system on purpose: the two views
  # that render BroadcastAnnouncement#link are the widest exposure and are vulnerable on main, so
  # the guard has to work with or without a design system present.
  describe "#safe_http_url" do
    it "returns an http(s) url unchanged" do
      expect(helper.safe_http_url("https://example.com")).to eq("https://example.com")
      expect(helper.safe_http_url("http://example.com")).to eq("http://example.com")
    end

    it "returns nil for a javascript: url" do
      expect(helper.safe_http_url("javascript:alert(1)")).to be_nil
    end

    it "returns nil for a data: url" do
      expect(helper.safe_http_url("data:text/html,<script>alert(1)</script>")).to be_nil
    end

    # The anchoring bypass: a real URL appended to a dangerous one satisfied the unanchored pattern.
    it "returns nil when a real url is appended to a dangerous one" do
      expect(helper.safe_http_url("javascript:alert(1) http://decoy.example.com")).to be_nil
    end

    it "returns nil for blank" do
      expect(helper.safe_http_url("")).to be_nil
      expect(helper.safe_http_url(nil)).to be_nil
    end
  end
end
