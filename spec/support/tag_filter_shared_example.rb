RSpec.shared_examples_for "allows filtering by tag" do |taggable_class, tag_filter = :by_tags|
  let(:described_class) { taggable_class.to_s.underscore.to_sym }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }

  let(:tag) { create(:tag, name: "New Years", type: taggable_class.to_s, organization:) }
  let(:other_tag) { create(:tag, name: "Christmas", type: taggable_class.to_s, organization:) }

  let!(:with_tag) { create(described_class, name: "AAAA", tags: [tag, other_tag], organization:) }
  let!(:with_other_tag) { create(described_class, name: "BBBB", tags: [other_tag], organization:) }
  let!(:with_no_tags) { create(described_class, name: "CCCC", tags: [], organization:) }

  let(:params) { {filters: filter_params} }

  context "when tag filter includes tag" do
    let(:filter_params) { {tag_filter => "New Years"} }

    it "shows records with filtered tag" do
      get index_path

      expect(response).to be_successful

      expect(response.body).to include("AAAA")

      page = Nokogiri::HTML(response.body)
      filtered_rows_count = page.css("table tbody tr").count

      expect(filtered_rows_count).to eq(1)
    end
  end

  context "when tag filter is empty" do
    let(:filter_params) { {tag_filter => ""} }

    it "shows all records" do
      get index_path

      expect(response).to be_successful

      expect(response.body).to include("AAAA")
      expect(response.body).to include("BBBB")
      expect(response.body).to include("CCCC")

      page = Nokogiri::HTML(response.body)
      filtered_rows_count = page.css("table tbody tr").count

      expect(filtered_rows_count).to eq(3)
    end
  end
end
