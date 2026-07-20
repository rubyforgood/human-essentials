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
        quantity_start: 0,
        quantity_in: 10,
        quantity_out: 5,
        quantity_adjustment: 0,
        change: 5,
        quantity_end: 5,
        total_quantity_start: 0,
        total_quantity_in: 13,
        total_quantity_out: 7,
        total_quantity_adjustment: 2,
        total_change: 8,
        total_quantity_end: 8
      },
      {
        # Donation (+3) flows in and the transfer (-2) flows out. The
        # adjustment (+3) lands in the adjustment column, as does the audit:
        # it counts an absolute quantity of 3 when the running quantity is 4,
        # so it contributes its delta of -1, netting +2.
        item_id: items[1].id,
        item_name: items[1].name,
        quantity_start: 0,
        quantity_in: 3,
        quantity_out: 2,
        quantity_adjustment: 2,
        change: 3,
        quantity_end: 3,
        total_quantity_start: 0,
        total_quantity_in: 13,
        total_quantity_out: 7,
        total_quantity_adjustment: 2,
        total_change: 8,
        total_quantity_end: 8
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
      Event.last.update(event_time: 10.days.ago)
      create(:donation, :with_items, item: old_items[1], item_quantity: 8, storage_location: storage_location)
      Event.last.update(event_time: 12.days.ago)
      distribution = create(:distribution, :with_items, item: old_items[1], item_quantity: 5, storage_location: storage_location)
      DistributionEvent.publish(distribution)
      Event.last.update(event_time: 10.days.ago)
    end

    let(:filtered_result) do
      [
        {
          item_id: old_items[0].id,
          item_name: old_items[0].name,
          quantity_start: 0,
          quantity_in: 10,
          quantity_out: 0,
          quantity_adjustment: 0,
          change: 10,
          quantity_end: 10,
          total_quantity_start: 8,
          total_quantity_in: 10,
          total_quantity_out: 5,
          total_quantity_adjustment: 0,
          total_change: 5,
          total_quantity_end: 13
        },
        {
          # Donated (+8) before the window, so it only shows in the starting
          # quantity; the in-window distribution (-5) flows out.
          item_id: old_items[1].id,
          item_name: old_items[1].name,
          quantity_start: 8,
          quantity_in: 0,
          quantity_out: 5,
          quantity_adjustment: 0,
          change: -5,
          quantity_end: 3,
          total_quantity_start: 8,
          total_quantity_in: 10,
          total_quantity_out: 5,
          total_quantity_adjustment: 0,
          total_change: 5,
          total_quantity_end: 13
        }
      ].map(&:with_indifferent_access)
    end

    it "returns array of hashes" do
      expect(subject.to_a).to match_array(filtered_result)
    end
  end

  context "when a donation has been edited" do
    let!(:fresh_organization) { create(:organization) }
    let(:location) { create(:storage_location, organization: fresh_organization) }
    let(:item) { create(:item, organization: fresh_organization) }

    subject { described_class.new(organization: fresh_organization, storage_location: location).call }

    it "only counts the latest version of the donation" do
      donation = create(:donation, :with_items, item: item, item_quantity: 10, storage_location: location, organization: fresh_organization)
      donation.line_items.first.update!(quantity: 25)
      DonationEvent.publish(donation)

      row = subject.to_a.find { |r| r["item_id"] == item.id }
      expect(row["quantity_in"]).to eq(25)
      expect(row["quantity_end"]).to eq(25)
    end
  end

  context "when a donation has been destroyed" do
    let!(:fresh_organization) { create(:organization) }
    let(:location) { create(:storage_location, organization: fresh_organization) }
    let(:item) { create(:item, organization: fresh_organization) }

    subject { described_class.new(organization: fresh_organization, storage_location: location).call }

    it "does not count the destroyed donation or list its item" do
      donation = create(:donation, :with_items, item: item, item_quantity: 10, storage_location: location, organization: fresh_organization)
      DonationDestroyEvent.publish(donation)

      expect(subject.to_a).to be_empty
    end
  end

  context "with kit allocations" do
    let!(:fresh_organization) { create(:organization) }
    let(:location) { create(:storage_location, organization: fresh_organization) }
    let(:content_item) { create(:item, organization: fresh_organization) }
    let(:kit) do
      kit_params = {
        organization_id: fresh_organization.id,
        name: "Flow Test Kit",
        line_items_attributes: [{item_id: content_item.id, quantity: 2}]
      }
      KitCreateService.new(organization_id: fresh_organization.id, kit_params: kit_params).tap(&:call).kit
    end

    subject { described_class.new(organization: fresh_organization, storage_location: location).call }

    it "counts kit contents flowing out and assembled kits flowing in" do
      create(:donation, :with_items, item: content_item, item_quantity: 10, storage_location: location, organization: fresh_organization)
      KitAllocateEvent.publish(kit, location.id, 3)

      rows = subject.to_a.index_by { |r| r["item_id"] }
      expect(rows[kit.id]["quantity_in"]).to eq(3)
      expect(rows[kit.id]["quantity_end"]).to eq(3)
      expect(rows[content_item.id]["quantity_in"]).to eq(10)
      expect(rows[content_item.id]["quantity_out"]).to eq(6)
      expect(rows[content_item.id]["quantity_end"]).to eq(4)
    end
  end
end
