# frozen_string_literal: true

# Summarizes how each item's quantity at a storage location changed over a
# date range: quantity at start, in, out, adjustments/audits, and at end.
#
# Numbers are reported "as of now": an edit or deletion is backdated to when
# the record was first created, so a donation of 100 that was later edited to
# 150 shows 150 on its original date, and a deleted donation shows nothing.
#
# To do this we replay the inventory once (the same replay used everywhere
# else, so audits, kits and edits are handled exactly as InventoryAggregate
# handles them), record the change each event made at this location, and
# attribute that change to the time its record was first created. Start and
# end quantities are then the current quantity minus the changes attributed
# after those times, so start + change always equals end.
class ItemsFlowQuery
  Result = Struct.new(:rows, :totals, keyword_init: true)

  ADJUSTMENT_TYPES = %w[AdjustmentEvent AuditEvent].freeze
  # These events stand alone rather than being a version of their record, so
  # their changes stay at their own event time.
  STANDALONE_TYPES = %w[KitAllocateEvent KitDeallocateEvent AuditEvent UpdateExistingEvent].freeze

  # @param organization [Organization]
  # @param storage_location [StorageLocation]
  # @param date_range [Range<Time>, nil] nil means everything since the last snapshot
  def initialize(organization:, storage_location:, date_range: nil)
    @organization = organization
    @storage_location = storage_location
    @date_range = date_range
  end

  # @return [Result]
  def call
    current, changes = replay
    flows = window_flows(changes)
    start_quantities = quantities_without(current, changes) { |time| @date_range.nil? || time >= @date_range.begin }
    end_quantities = quantities_without(current, changes) { |time| @date_range && time > @date_range.end }

    item_ids = (flows.keys + start_quantities.keys + end_quantities.keys).uniq
    names = Item.where(id: item_ids).pluck(:id, :name).to_h

    rows = item_ids.filter_map do |item_id|
      flow = flows[item_id]
      start_qty = start_quantities[item_id]
      end_qty = end_quantities[item_id]
      next if flow.values.all?(&:zero?) && start_qty.zero? && end_qty.zero?

      {
        item_id: item_id,
        item_name: names[item_id],
        quantity_start: start_qty,
        quantity_in: flow[:in],
        quantity_out: flow[:out],
        quantity_adjustment: flow[:adjustment],
        change: end_qty - start_qty,
        quantity_end: end_qty
      }
    end.sort_by { |row| row[:item_name].to_s }

    totals = %i[quantity_start quantity_in quantity_out quantity_adjustment change quantity_end]
      .index_with { |column| rows.sum { |row| row[column] } }

    Result.new(rows: rows, totals: totals)
  end

  private

  Change = Struct.new(:key, :time, :adjustment, :item_id, :quantity, keyword_init: true)

  # Replays the inventory, recording the change each event made to each item
  # at this location.
  # @return [Array(Hash<Integer, Integer>, Array<Change>)] current quantities and changes
  def replay
    running = Hash.new(0)
    changes = []
    first_seen = {} # record key => time its first event happened
    touched_by = {} # record key => item ids its latest version touched here

    InventoryAggregate.inventory_for(@organization.id) do |event, inventory|
      items = inventory.storage_locations[@storage_location.id]&.items || {}
      if event.is_a?(SnapshotEvent)
        running = Hash.new(0).merge(items.transform_values(&:quantity))
        next
      end

      key = STANDALONE_TYPES.include?(event.type) ? [:event, event.id] : [event.eventable_type, event.eventable_id]
      first_seen[key] ||= event.event_time
      # an edit can remove an item, so also check what the previous version touched
      touched = event.data.items.filter_map do |line_item|
        line_item.item_id if [line_item.to_storage_location, line_item.from_storage_location].include?(@storage_location.id)
      end
      touched |= touched_by.fetch(key, [])
      touched_by[key] = touched

      touched.each do |item_id|
        quantity = items[item_id]&.quantity.to_i
        next if quantity == running[item_id]

        changes << Change.new(key: key, time: first_seen[key], adjustment: ADJUSTMENT_TYPES.include?(event.type),
          item_id: item_id, quantity: quantity - running[item_id])
        running[item_id] = quantity
      end
    end

    [running, changes]
  end

  # Nets each record's changes (so an edited donation counts once, at its
  # latest quantity) and sorts them into in, out and adjustment.
  # @return [Hash<Integer, Hash>] item_id => {in:, out:, adjustment:}
  def window_flows(changes)
    flows = Hash.new { |hash, item_id| hash[item_id] = {in: 0, out: 0, adjustment: 0} }
    in_window = changes.select { |change| @date_range.nil? || @date_range.cover?(change.time) }
    in_window.group_by { |change| [change.key, change.item_id] }.each do |(_, item_id), record_changes|
      net = record_changes.sum(&:quantity)
      flow = flows[item_id]
      if record_changes.first.adjustment
        flow[:adjustment] += net
      elsif net.positive?
        flow[:in] += net
      else
        flow[:out] -= net
      end
    end
    flows
  end

  # Current quantities with the changes attributed to the selected times undone.
  # @yieldparam time [Time] when a change is attributed to
  # @return [Hash<Integer, Integer>] item_id => quantity
  def quantities_without(current, changes)
    quantities = Hash.new(0).merge(current)
    changes.each { |change| quantities[change.item_id] -= change.quantity if yield(change.time) }
    quantities
  end
end
