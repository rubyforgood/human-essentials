require "rails_helper"

RSpec.describe "Kaminari configuration" do
  describe "default_per_page setting" do
    after(:each) do
      # Reset Kaminari configuration after each test
      Kaminari.configure do |config|
        config.default_per_page = 50
      end
    end

    context "in development environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        # Reload the configuration file
        load Rails.root.join("config/initializers/kaminari_config.rb")
      end

      it "sets default_per_page to 5" do
        expect(Kaminari.config.default_per_page).to eq(5)
      end
    end

    context "in staging environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))
        # Reload the configuration file
        load Rails.root.join("config/initializers/kaminari_config.rb")
      end

      it "sets default_per_page to 5" do
        expect(Kaminari.config.default_per_page).to eq(5)
      end
    end

    context "in production environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        # Reload the configuration file
        load Rails.root.join("config/initializers/kaminari_config.rb")
      end

      it "sets default_per_page to 50" do
        expect(Kaminari.config.default_per_page).to eq(50)
      end
    end
  end
end
