# frozen_string_literal: true

RSpec.describe ItemsFlowQuery do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:date_range) { nil }

  subject(:result) { described_class.new(organization: organization, storage_location: storage_location, date_range: date_range).call }

  def rows_by_item
    result.rows.index_by { |row| row[:item_id] }
  end

  def donate(item, quantity)
    create(:donation, :with_items, item: item, item_quantity: quantity, storage_location: storage_location, organization: organization)
  end

  def month(year, month)
    Time.zone.local(year, month, 1).all_month
  end

  context "with donations, distributions, adjustments, transfers and audits" do
    let(:items) { create_list(:item, 2, organization: organization) }

    before do
      donate(items[0], 10)
      distribution = create(:distribution, :with_items, item: items[0], item_quantity: 5, storage_location: storage_location, organization: organization)
      DistributionEvent.publish(distribution)
      donate(items[1], 3)
      adjustment = create(:adjustment, :with_items, item: items[1], item_quantity: 3, storage_location: storage_location, organization: organization)
      AdjustmentEvent.publish(adjustment)
      transfer = create(:transfer, :with_items, item: items[1], item_quantity: 2, from: storage_location,
        to: create(:storage_location, organization: organization), organization: organization)
      TransferEvent.publish(transfer)
      # counts 3 when there are 4, so it contributes -1
      audit = create(:audit, :with_items, item: items[1], item_quantity: 3, adjustment: adjustment, storage_location: storage_location, organization: organization)
      AuditEvent.publish(audit)
    end

    it "sorts each item's changes into in, out and adjustment columns" do
      expect(result.rows).to contain_exactly(
        {item_id: items[0].id, item_name: items[0].name, quantity_start: 0, quantity_in: 10, quantity_out: 5,
         quantity_adjustment: 0, change: 5, quantity_end: 5},
        {item_id: items[1].id, item_name: items[1].name, quantity_start: 0, quantity_in: 3, quantity_out: 2,
         quantity_adjustment: 2, change: 3, quantity_end: 3}
      )
      expect(result.totals).to eq(quantity_start: 0, quantity_in: 13, quantity_out: 7, quantity_adjustment: 2,
        change: 8, quantity_end: 8)
    end
  end

  context "with a date range" do
    let(:items) { create_list(:item, 2, organization: organization) }
    let(:date_range) { month(2026, 2) }

    before do
      travel_to(Time.zone.local(2026, 1, 15)) { donate(items[1], 8) }
      travel_to(Time.zone.local(2026, 2, 10)) do
        donate(items[0], 10)
        distribution = create(:distribution, :with_items, item: items[1], item_quantity: 5, storage_location: storage_location, organization: organization)
        DistributionEvent.publish(distribution)
      end
      travel_to(Time.zone.local(2026, 3, 5)) { donate(items[0], 4) }
    end

    it "counts flows inside the range and quantities at its start and end" do
      expect(rows_by_item[items[0].id]).to include(quantity_start: 0, quantity_in: 10, quantity_out: 0, quantity_end: 10)
      expect(rows_by_item[items[1].id]).to include(quantity_start: 8, quantity_in: 0, quantity_out: 5, quantity_end: 3)
    end
  end

  context "when a donation is edited after it was made" do
    let(:item) { create(:item, organization: organization) }

    before do
      travel_to(Time.zone.local(2026, 1, 15)) { @donation = donate(item, 100) }
      travel_to(Time.zone.local(2026, 3, 15)) do
        @donation.line_items.first.update!(quantity: 150)
        DonationEvent.publish(@donation.reload)
      end
    end

    context "in the range when it was made" do
      let(:date_range) { month(2026, 1) }

      it "counts the edited quantity on the original date" do
        expect(rows_by_item[item.id]).to include(quantity_start: 0, quantity_in: 150, change: 150, quantity_end: 150)
      end
    end

    context "in the range when it was edited" do
      let(:date_range) { month(2026, 3) }

      it "shows no flow for the edit" do
        expect(rows_by_item[item.id]).to include(quantity_start: 150, quantity_in: 0, quantity_out: 0, quantity_end: 150)
      end
    end
  end

  context "when an edit removes an item" do
    let(:items) { create_list(:item, 2, organization: organization) }

    before do
      donation = create(:donation, organization: organization, storage_location: storage_location,
        line_items_attributes: items.map { |item| {item_id: item.id, quantity: 5} })
      DonationEvent.publish(donation)
      donation.line_items.find_by(item_id: items[1].id).destroy!
      DonationEvent.publish(donation.reload)
    end

    it "does not list the removed item" do
      expect(rows_by_item.keys).to eq([items[0].id])
    end
  end

  context "when a donation is destroyed" do
    let(:item) { create(:item, organization: organization) }
    let(:date_range) { month(2026, 1) }

    before do
      travel_to(Time.zone.local(2026, 1, 15)) { @donation = donate(item, 10) }
      travel_to(Time.zone.local(2026, 3, 15)) { DonationDestroyEvent.publish(@donation) }
    end

    it "does not count it, even in the range it was made" do
      expect(result.rows).to be_empty
    end
  end

  context "with kit allocations" do
    let(:content_item) { create(:item, organization: organization) }
    let(:kit) do
      kit_params = {
        organization_id: organization.id,
        name: "Flow Test Kit",
        line_items_attributes: [{item_id: content_item.id, quantity: 2}]
      }
      KitCreateService.new(organization_id: organization.id, kit_params: kit_params).tap(&:call).kit
    end

    it "counts kit contents flowing out and assembled kits flowing in" do
      donate(content_item, 10)
      KitAllocateEvent.publish(kit, storage_location.id, 3)

      expect(rows_by_item[kit.id]).to include(quantity_in: 3, quantity_end: 3)
      expect(rows_by_item[content_item.id]).to include(quantity_in: 10, quantity_out: 6, quantity_end: 4)
    end
  end
end
