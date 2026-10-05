RSpec.describe SiteUrlsHelper, type: :helper do
  describe "#production_url" do
    it "defaults to the configured live site" do
      expect(helper.production_url).to eq("https://humanessentials.app/")
      expect(helper.production_url("/users/sign_in")).to eq("https://humanessentials.app/users/sign_in")
    end

    it "follows the configured host when the live site moves to another domain" do
      allow(Rails.application.config.x.site_urls).to receive(:production).and_return("https://humanessentialsapp.org")

      expect(helper.production_url("/users/sign_in")).to eq("https://humanessentialsapp.org/users/sign_in")
      expect(helper.production_host).to eq("humanessentialsapp.org")
    end
  end

  describe "#demo_url" do
    it "defaults to the configured demo site" do
      expect(helper.demo_url("/users/sign_in")).to eq("https://staging.humanessentials.app/users/sign_in")
    end
  end
end
