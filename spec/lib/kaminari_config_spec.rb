require "rails_helper"

RSpec.describe "Kaminari configuration" do
  describe "default_per_page setting" do
    # The default used to be 5 in development and staging and 50 elsewhere, and this spec
    # asserted that split. It is one number in every environment now, so that a page under
    # review looks like the page a bank sees; see docs/design-decisions.md.
    %w[development staging production test].each do |env|
      context "in the #{env} environment" do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env))
          load Rails.root.join("config/initializers/kaminari_config.rb")
        end

        it "sets default_per_page to Pagination::MEDIUM" do
          expect(Kaminari.config.default_per_page).to eq(Pagination::MEDIUM)
        end
      end
    end
  end

  describe Pagination do
    it "bands page sizes from largest rows to smallest" do
      expect(described_class::TALL).to be < described_class::MEDIUM
      expect(described_class::MEDIUM).to be < described_class::COMPACT
    end
  end
end
