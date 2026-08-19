require "rails_helper"

RSpec.describe EssentialsUiHelper, type: :helper do
  describe "#essentials_stats" do
    # A block given to `tag` renders nothing for a non-String, so an Integer value produced an
    # empty figure while every currency stat, already a String, looked fine.
    it "renders a numeric value" do
      html = helper.essentials_stats([{label: "Total items", value: 35_065}])
      expect(html).to include("35065")
    end

    it "renders a string value" do
      html = helper.essentials_stats([{label: "Spent", value: "$1,311.22"}])
      expect(html).to include("$1,311.22")
    end

    it "keeps the spec hook class the request specs match on" do
      html = helper.essentials_stats([{label: "Items", value: 12, value_class: "total_distributed"}])
      expect(html).to include('<span class="total_distributed">12</span>')
    end

    it "pairs each label with its value as a description list" do
      html = helper.essentials_stats([{label: "Total items", value: 3}])
      expect(html).to include("<dl")
      expect(html).to include("<dt")
      expect(html).to include("<dd")
      expect(html).not_to include("<h2")
    end
  end
end
