# frozen_string_literal: true

require "rspec"

RSpec.describe ItemsFlowQuery do
  let(:items) { create_list(:item, 2) }
  let!(:storage_location) { create(:storage_location, name: "here") }
  let(:organization) { storage_location.organization }
  let!(:result) do
    [
      {
        item_id: items[0].id,
        item_name: items[0].name,
        quantity_in: 10,
        quantity_out: 5,
        change: 5,
        total_quantity_in: 19,
        total_quantity_out: 7,
        total_change: 12
      },
      {
        item_id: items[1].id,
        item_name: items[1].name,
        quantity_in: 9,
        quantity_out: 2,
        change: 7,
        total_quantity_in: 19,
        total_quantity_out: 7,
        total_change: 12
      }
    ].map(&:with_indifferent_access)
  end

  before do
    create(:donation, :with_items, item: items[0], item_quantity: 10, storage_location: storage_location)
    distribution = create(:distribution, :with_items, item: items[0], item_quantity: 5, storage_location: storage_location)
    DistributionEvent.publish(distribution)
    create(:donation, :with_items, item: items[1], item_quantity: 3, storage_location: storage_location)
    adjustment = create(:adjustment, :with_items, item: items[1], item_quantity: 3, storage_location: storage_location)
    AdjustmentEvent.publish(adjustment)
    transfer = create(:transfer, :with_items, item: items[1], item_quantity: 2, from: storage_location, to: create(:storage_location))
    TransferEvent.publish(transfer)
    audit = create(:audit, :with_items, item: items[1], item_quantity: 3, adjustment: adjustment, storage_location: storage_location)
    AuditEvent.publish(audit)
  end

  subject { described_class.new(organization: organization, storage_location: storage_location).call }

  context "without filter params" do
    it "returns array of hashes" do
      expect(subject.to_a).to match_array(result)
    end
  end

  context "with filter params" do
    let(:filter_params) { [11.days.ago, 9.days.ago] }
    let!(:old_items) { create_list(:item, 2) }
    let(:other_location) { create(:storage_location, organization: organization) }

    subject { described_class.new(organization: organization, storage_location: storage_location, filter_params: filter_params).call }

    before do
      create(:donation, :with_items, item: old_items[0], item_quantity: 10, storage_location: storage_location)
      Event.last.update(created_at: 10.days.ago)
      create(:donation, :with_items, item: old_items[1], item_quantity: 8, storage_location: storage_location)
      distribution = create(:distribution, :with_items, item: old_items[1], item_quantity: 5, storage_location: storage_location)
      DistributionEvent.publish(distribution)
      Event.last.update(created_at: 10.days.ago)
    end

    let(:filtered_result) do
      [
        {
          item_id: old_items[0].id,
          item_name: old_items[0].name,
          quantity_in: 10,
          quantity_out: 0,
          change: 10,
          total_quantity_in: 10,
          total_quantity_out: 5,
          total_change: 5
        },
        {
          item_id: old_items[1].id,
          item_name: old_items[1].name,
          quantity_in: 0,
          quantity_out: 5,
          change: -5,
          total_quantity_in: 10,
          total_quantity_out: 5,
          total_change: 5
        }
      ].map(&:with_indifferent_access)
    end

    it "returns array of hashes" do
      expect(subject.to_a).to match_array(filtered_result)
    end
  end
end
