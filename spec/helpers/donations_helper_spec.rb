RSpec.describe DonationsHelper, type: :helper do
  describe "#options_with_new" do
    it "returns the options array including 'new' option for DonationSite" do
      donation_sites_relation = DonationSite.all
      options = helper.options_with_new(donation_sites_relation)
      expect(options.last).to eq(["---Create New Donation site---", "new"])
    end

    it "returns the options array including 'new' option for ProductDrive" do
      product_drives_relation = ProductDrive.all
      options = helper.options_with_new(product_drives_relation)
      expect(options.last).to eq(["---Create New Product Drive---", "new"])
    end
  end
end
