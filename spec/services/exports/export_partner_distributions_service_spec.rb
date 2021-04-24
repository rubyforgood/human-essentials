require "rails_helper"

describe Exports::ExportPartnerDistributionsService do
  let(:item) { create(:item) }
  let(:distribution) { create(:distribution, :with_items, item: item, organization: @organization, issued_at: 3.days.ago) }
  let(:distributions) { Array.new(3, distribution)}

  subject do
    described_class.new(distributions,  ["Partner", "Total Value", "Delivery Method",
      "State", "Agency Representative"])
  end

  describe ".call" do

    it "includes default headers in the first row" do
      expect(subject.call.first).to include("Date of Distribution", "Source Inventory",
                                            "Total Items", item.name)
    end
    
    it "includes optional headers when provided" do
      expect(subject.call.first).to include("Partner", "Total Value", "Delivery Method",
                                            "State", "Agency Representative", item.name)
    end

    it "includes rows for each distribution" do
      rows = distributions.length
      expect(subject.call.length).to equal(rows + 1) # +1 to account for headers
    end

    it "includes the correct number of columns" do
      expect(subject.call.second.length).to equal(subject.call.first.length)
    end
  end
end
 