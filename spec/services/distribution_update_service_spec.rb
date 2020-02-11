require 'spec_helper'
require_relative '../support/env_helper'

RSpec.describe DistributionUpdateService, type: :service do
  describe "call" do
    # TODO: this function was extracted to the service object - do we need a parallel test?

    let!(:distribution) { FactoryBot.create(:distribution, :with_items, item_quantity: 10) }
    let!(:new_attributes) { { line_items_attributes: { "0": { item_id: distribution.line_items.first.item_id, quantity: 2 } } } }

    it "replaces a big distribution with a smaller one, resulting in increased stored quantities" do
      expect do
        DistributionUpdateService.new(distribution, new_attributes).call
      end.to change { distribution.storage_location.size }.by(8)
    end
  end
end
