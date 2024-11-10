describe PartnersHelper, type: :helper do
  describe "show_submit_for_approval?" do
    it "returns true if invited" do
      partner = build_stubbed(:partner, status: :invited)
      expect(helper.show_submit_for_approval?(partner)).to be_truthy
    end

    it "returns true if recertification required" do
      partner = build_stubbed(:partner, status: :recertification_required)
      expect(helper.show_submit_for_approval?(partner)).to be_truthy
    end

    it "returns false if awaiting review" do
      partner = build_stubbed(:partner, status: :awaiting_review)
      expect(helper.show_submit_for_approval?(partner)).to be_falsey
    end
  end

  describe "partial_display_name" do
    it "returns the humanized name by default" do
      expect(helper.partial_display_name("agency_stability")).to eq("Agency stability")
    end

    it "returns the custom display name when overridden" do
      expect(helper.partial_display_name("attached_documents")).to eq("Additional Documents")
    end
  end
end
