describe PartnersHelper, type: :helper do
  describe "partial_display_name" do
    it "returns the humanized name by default" do
      expect(helper.partial_display_name("agency_stability")).to eq("Agency stability")
    end

    it "returns the custom display name when overridden" do
      expect(helper.partial_display_name("attached_documents")).to eq("Additional Documents")
    end
  end
end
