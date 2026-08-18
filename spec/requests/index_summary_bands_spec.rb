require "rails_helper"

# The four summary reports were removed: they were weaker copies of the index pages, with fewer
# filters and no full table. Their figures now sit at the top of the index, driven by the same
# filters as the table.
#
# This carries over the coverage those reports had -- that the totals respond correctly to a
# date range -- to the pages that now own it, and checks the old URLs still land somewhere.
RSpec.describe "Index summary bands", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in(user) }

  def date_range_param(range)
    {filters: {date_range: range.map { |d| d.to_fs(:date_picker) }.join(" - ")}}
  end

  describe "the retired summary reports" do
    {
      reports_distributions_summary_path: "/distributions",
      reports_donations_summary_path: "/donations",
      reports_purchases_summary_path: "/purchases",
      reports_product_drives_summary_path: "/product_drives"
    }.each do |old_path, destination|
      it "redirects #{old_path} to #{destination}" do
        get public_send(old_path)
        expect(response).to redirect_to(destination)
      end
    end
  end

  describe "/distributions" do
    before do
      create :distribution, :with_items, item_quantity: 2, issued_at: 0.days.ago, organization: organization
      create :distribution, :with_items, item_quantity: 3, issued_at: 1.day.ago, organization: organization
      create :distribution, :with_items, item_quantity: 7, issued_at: 3.days.ago, organization: organization
      create :distribution, :with_items, item_quantity: 11, issued_at: 10.days.ago, organization: organization
      create :distribution, :with_items, item_quantity: 13, issued_at: 20.days.ago, organization: organization
      create :distribution, :with_items, item_quantity: 17, issued_at: 30.days.ago, organization: organization
    end

    {
      "today" => [[0, 0], 2],
      "yesterday" => [[1, 1], 3],
      "a weekish ago" => [[14, 7], 11],
      "two weekish ago" => [[25, 7], 24],
      "a long time" => [[900, 1], 51]
    }.each do |label, (days, expected)|
      it "totals #{expected} items for #{label}" do
        get distributions_path, params: date_range_param([days.first.days.ago, days.last.days.ago])
        expect(assigns(:total_items_all_distributions)).to eq(expected)
        expect(response.body).to include("Items distributed")
      end
    end
  end

  describe "the band on each index" do
    it "shows distribution figures" do
      create(:distribution, :with_items, item_quantity: 5, organization: organization)
      get distributions_path
      expect(response.body).to include("Distributions").and include("Items distributed").and include("Total value")
    end

    it "shows donation figures" do
      create(:donation, :with_items, item_quantity: 4, organization: organization)
      get donations_path
      expect(response.body).to include("Items received").and include("Money raised").and include("In-kind value")
    end

    it "shows purchase figures" do
      create(:purchase, :with_items, item_quantity: 6, organization: organization)
      get purchases_path
      expect(response.body).to include("Items purchased").and include("Amount spent")
    end

    it "shows product drive figures" do
      create(:product_drive, organization: organization)
      get product_drives_path
      expect(response.body).to include("Drives").and include("Items received").and include("In-kind value")
    end
  end
end
