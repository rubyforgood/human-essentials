# frozen_string_literal: true

RSpec.describe ItemsFlowQuery do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:date_range) { nil }

  subject(:result) { described_class.new(organization: organization, storage_location: storage_location, date_range: date_range).call }

  def rows_by_item
    result.rows.index_by(&:item_id)
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
        have_attributes(item_id: items[0].id, item_name: items[0].name, quantity_start: 0, quantity_in: 10, quantity_out: 5,
          quantity_adjustment: 0, change: 5, quantity_end: 5),
        have_attributes(item_id: items[1].id, item_name: items[1].name, quantity_start: 0, quantity_in: 3, quantity_out: 2,
          quantity_adjustment: 2, change: 3, quantity_end: 3)
      )
      expect(result.totals).to have_attributes(quantity_start: 0, quantity_in: 13, quantity_out: 7, quantity_adjustment: 2,
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
      expect(rows_by_item[items[0].id]).to have_attributes(quantity_start: 0, quantity_in: 10, quantity_out: 0, quantity_end: 10)
      expect(rows_by_item[items[1].id]).to have_attributes(quantity_start: 8, quantity_in: 0, quantity_out: 5, quantity_end: 3)
    end
  end

  context "when the date range starts before the inventory snapshot" do
    let(:item) { create(:item, organization: organization) }

    before do
      travel_to(Time.zone.local(2026, 1, 10)) { donate(item, 8) }
      travel_to(Time.zone.local(2026, 1, 31, 12)) { SnapshotEvent.publish(organization) }
      travel_to(Time.zone.local(2026, 2, 10)) { donate(item, 5) }
    end

    context "and ends after it" do
      let(:date_range) { Time.zone.local(2026, 1, 15)..Time.zone.local(2026, 2, 28).end_of_day }

      it "leaves the start quantity and change blank and counts flows from the snapshot on" do
        expect(result.rows).to contain_exactly(
          have_attributes(item_id: item.id, quantity_start: nil, quantity_in: 5, quantity_out: 0, change: nil, quantity_end: 13)
        )
        expect(result.totals).to have_attributes(quantity_start: nil, quantity_in: 5, change: nil, quantity_end: 13)
        expect(result.history_start).to eq(Time.zone.local(2026, 1, 31, 12))
      end
    end

    context "and ends before it" do
      let(:date_range) { Time.zone.local(2026, 1, 1)..Time.zone.local(2026, 1, 20).end_of_day }

      it "has no rows and no known totals" do
        expect(result.rows).to be_empty
        expect(result.totals).to have_attributes(quantity_start: nil, quantity_in: nil, quantity_out: nil,
          quantity_adjustment: nil, change: nil, quantity_end: nil)
        expect(result.history_start).to eq(Time.zone.local(2026, 1, 31, 12))
      end
    end

    context "when the date range starts after the snapshot" do
      let(:date_range) { month(2026, 2) }

      it "starts from the snapshot quantity" do
        expect(result.rows).to contain_exactly(
          have_attributes(item_id: item.id, quantity_start: 8, quantity_in: 5, change: 5, quantity_end: 13)
        )
        expect(result.history_start).to be_nil
      end
    end
  end

  context "with item names in mixed case" do
    let!(:items) { %w[banana Cherry apple].map { |name| create(:item, name: name, organization: organization) } }

    before { items.each { |item| donate(item, 1) } }

    it "sorts rows by name, ignoring case" do
      expect(result.rows.map(&:item_name)).to eq(%w[apple banana Cherry])
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
        expect(rows_by_item[item.id]).to have_attributes(quantity_start: 0, quantity_in: 150, change: 150, quantity_end: 150)
      end
    end

    context "in the range when it was edited" do
      let(:date_range) { month(2026, 3) }

      it "shows no flow for the edit" do
        expect(rows_by_item[item.id]).to have_attributes(quantity_start: 150, quantity_in: 0, quantity_out: 0, quantity_end: 150)
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

  context "when successive edits each replace the donated item" do
    let(:items) { create_list(:item, 3, organization: organization) }

    before do
      donation = donate(items[0], 5)
      items.drop(1).each do |item|
        donation.line_items.first.update!(item_id: item.id)
        DonationEvent.publish(donation.reload)
      end
    end

    it "only counts the item from the latest edit" do
      expect(result.rows).to contain_exactly(have_attributes(item_id: items[2].id, quantity_in: 5, quantity_end: 5))
    end
  end

  context "when an edit moves a donation to another storage location" do
    let(:item) { create(:item, organization: organization) }
    let(:other_location) { create(:storage_location, organization: organization) }

    before do
      donation = donate(item, 5)
      donation.update!(storage_location: other_location)
      DonationEvent.publish(donation.reload)
    end

    it "counts it only at the new location" do
      expect(result.rows).to be_empty
      other_result = described_class.new(organization: organization, storage_location: other_location).call
      expect(other_result.rows).to contain_exactly(have_attributes(item_id: item.id, quantity_in: 5, quantity_end: 5))
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

  context "with a transfer into this location" do
    let(:item) { create(:item, organization: organization) }
    let(:source) { create(:storage_location, organization: organization) }

    before do
      create(:donation, :with_items, item: item, item_quantity: 10, storage_location: source, organization: organization)
      transfer = create(:transfer, :with_items, item: item, item_quantity: 4, from: source, to: storage_location, organization: organization)
      TransferEvent.publish(transfer)
    end

    it "counts it as in at the receiving location and out at the source" do
      expect(result.rows).to contain_exactly(have_attributes(item_id: item.id, quantity_in: 4, quantity_out: 0, quantity_end: 4))
      source_result = described_class.new(organization: organization, storage_location: source).call
      expect(source_result.rows).to contain_exactly(have_attributes(item_id: item.id, quantity_in: 10, quantity_out: 4, quantity_end: 6))
    end
  end

  context "when records made in the range are destroyed later" do
    let(:item) { create(:item, organization: organization) }
    let(:other_location) { create(:storage_location, organization: organization) }
    let(:date_range) { month(2026, 1) }

    before do
      travel_to(Time.zone.local(2026, 1, 10)) { donate(item, 10) }
      travel_to(Time.zone.local(2026, 1, 15)) do
        @distribution = create(:distribution, :with_items, item: item, item_quantity: 4, storage_location: storage_location, organization: organization)
        DistributionEvent.publish(@distribution)
        @transfer = create(:transfer, :with_items, item: item, item_quantity: 3, from: storage_location, to: other_location, organization: organization)
        TransferEvent.publish(@transfer)
        @purchase = create(:purchase, :with_items, item: item, item_quantity: 6, storage_location: storage_location, organization: organization)
      end
      travel_to(Time.zone.local(2026, 3, 1)) do
        DistributionDestroyEvent.publish(@distribution)
        TransferDestroyEvent.publish(@transfer)
        PurchaseDestroyEvent.publish(@purchase)
      end
    end

    it "does not count them, even in the range they were made" do
      expect(result.rows).to contain_exactly(have_attributes(item_id: item.id, quantity_start: 0, quantity_in: 10, quantity_out: 0, quantity_end: 10))
      other_result = described_class.new(organization: organization, storage_location: other_location, date_range: date_range).call
      expect(other_result.rows).to be_empty
    end
  end

  context "when a record from before event tracking is edited" do
    let(:item) { create(:item, organization: organization) }

    before do
      travel_to(Time.zone.local(2026, 1, 10)) do
        @donation = donate(item, 10)
        Event.where(eventable: @donation).delete_all
      end
      travel_to(Time.zone.local(2026, 3, 10)) do
        previous = @donation.line_items.map(&:dup)
        @donation.line_items.first.update!(quantity: 15)
        UpdateExistingEvent.publish(@donation.reload, previous, storage_location)
      end
    end

    context "in the range when the record was made" do
      let(:date_range) { month(2026, 1) }

      it "does not backdate the edit" do
        expect(result.rows).to be_empty
      end
    end

    context "in the range when it was edited" do
      let(:date_range) { month(2026, 3) }

      it "counts the edit when it was made" do
        expect(result.rows).to contain_exactly(have_attributes(item_id: item.id, quantity_start: 0, quantity_in: 5, quantity_end: 5))
      end
    end
  end

  context "with a mixed history over several months" do
    let(:items) { create_list(:item, 2, organization: organization) }
    let(:other_location) { create(:storage_location, organization: organization) }
    let(:months) { (1..4).map { |m| month(2026, m) } }

    before do
      travel_to(Time.zone.local(2026, 1, 5)) do
        @donation = donate(items[0], 50)
        donate(items[1], 30)
      end
      travel_to(Time.zone.local(2026, 2, 5)) do
        distribution = create(:distribution, :with_items, item: items[0], item_quantity: 12, storage_location: storage_location, organization: organization)
        DistributionEvent.publish(distribution)
        transfer = create(:transfer, :with_items, item: items[1], item_quantity: 5, from: storage_location, to: other_location, organization: organization)
        TransferEvent.publish(transfer)
      end
      travel_to(Time.zone.local(2026, 3, 5)) do
        @donation.line_items.first.update!(quantity: 60)
        DonationEvent.publish(@donation.reload)
        adjustment = create(:adjustment, :with_items, item: items[1], item_quantity: -4, storage_location: storage_location, organization: organization)
        AdjustmentEvent.publish(adjustment)
      end
      travel_to(Time.zone.local(2026, 4, 5)) do
        audit = create(:audit, :with_items, item: items[0], item_quantity: 40, storage_location: storage_location, organization: organization)
        AuditEvent.publish(audit)
      end
    end

    it "adds up within each row, chains from one month to the next, and ends at the current inventory" do
      results = months.map { |range| described_class.new(organization: organization, storage_location: storage_location, date_range: range).call }
      ends = ->(r) { r.rows.to_h { |row| [row.item_id, row.quantity_end] }.reject { |_, quantity| quantity.zero? } }
      starts = ->(r) { r.rows.to_h { |row| [row.item_id, row.quantity_start] }.reject { |_, quantity| quantity.zero? } }

      results.each do |r|
        r.rows.each { |row| expect(row.quantity_start + row.change).to eq(row.quantity_end) }
      end
      results.each_cons(2) do |earlier, later|
        expect(starts.call(later)).to eq(ends.call(earlier))
      end
      current = InventoryAggregate.inventory_for(organization.id).storage_locations[storage_location.id].items
        .transform_values(&:quantity).reject { |_, quantity| quantity.zero? }
      expect(ends.call(results.last)).to eq(current)
      # The March edit (50 -> 60) is backdated to the January donation.
      expect(results.first.rows.find { |row| row.item_id == items[0].id }.quantity_in).to eq(60)
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

      expect(rows_by_item[kit.id]).to have_attributes(quantity_in: 3, quantity_end: 3)
      expect(rows_by_item[content_item.id]).to have_attributes(quantity_in: 10, quantity_out: 6, quantity_end: 4)
    end

    it "counts deallocated kits flowing out and their contents flowing back in" do
      donate(content_item, 10)
      KitAllocateEvent.publish(kit, storage_location.id, 3)
      KitDeallocateEvent.publish(kit, storage_location.id, 1)

      expect(rows_by_item[kit.id]).to have_attributes(quantity_in: 3, quantity_out: 1, quantity_end: 2)
      expect(rows_by_item[content_item.id]).to have_attributes(quantity_in: 12, quantity_out: 6, quantity_end: 6)
    end
  end
end
