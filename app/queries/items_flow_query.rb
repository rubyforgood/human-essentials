# frozen_string_literal: true

# Summarizes how each item's quantity at a storage location changed over a
# date range: quantity at start, in, out, adjustments/audits, and at end.
#
# Numbers are reported "as of now": an edit or deletion is backdated to when
# the record was first created, so a donation of 100 that was later edited to
# 150 shows 150 on its original date, and a deleted donation shows nothing.
# The exception is records from before event tracking began, whose edits are
# stored as UpdateExistingEvents; those edits are dated when they were made,
# and count as in or out by the sign of the change (so reducing such a
# distribution shows as in).
#
# To do this we replay the inventory once (the same replay used everywhere
# else, so audits, kits and edits are handled exactly as InventoryAggregate
# handles them) and total up the net change each record made to each item at
# this location, dated to when the record was first created. Records from
# before the range make up the start quantity and records within it make up
# the in, out and adjustment columns, so start + change always equals end.
#
# The replay starts from the organization's most recent usable snapshot, so
# nothing is known about quantities before it. If the range starts before the
# snapshot, the start quantity and change are left blank (nil) and in, out and
# adjustment only count from the snapshot on. If the whole range is before the
# snapshot, there are no rows.
class ItemsFlowQuery
  # @!attribute history_start [Time, nil] when the inventory history begins, if
  #   the range starts before then (so some quantities are unknown)
  Result = Data.define(:rows, :totals, :history_start)

  # How one item's quantity moved over the date range. The totals row has no
  # item. Quantities that can't be known are nil.
  Row = Data.define(:item_id, :item_name, :quantity_start, :quantity_in, :quantity_out, :quantity_adjustment, :quantity_end) do
    # @param rows [Array<Row>]
    # @param start_known [Boolean]
    # @return [Row]
    def self.total(rows, start_known: true)
      new(
        item_id: nil,
        item_name: nil,
        quantity_start: (rows.sum(&:quantity_start) if start_known),
        quantity_in: rows.sum(&:quantity_in),
        quantity_out: rows.sum(&:quantity_out),
        quantity_adjustment: rows.sum(&:quantity_adjustment),
        quantity_end: rows.sum(&:quantity_end)
      )
    end

    # A totals row for a range with no known quantities.
    # @return [Row]
    def self.unknown
      new(item_id: nil, item_name: nil, quantity_start: nil, quantity_in: nil, quantity_out: nil,
        quantity_adjustment: nil, quantity_end: nil)
    end

    # @return [Integer, nil] nil when the start quantity isn't known
    def change
      quantity_end - quantity_start if quantity_start && quantity_end
    end

    def empty?
      [quantity_start, quantity_in, quantity_out, quantity_adjustment, quantity_end].compact.all?(&:zero?)
    end
  end

  ADJUSTMENT_TYPES = [AdjustmentEvent, AuditEvent].freeze

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
    history_start, snapshot_quantities, records = replay
    if before?(@date_range&.end, history_start)
      return Result.new(rows: [], totals: Row.unknown, history_start: history_start)
    end

    start_known = !before?(@date_range&.begin, history_start)
    changes_by_item = records.flat_map(&:item_changes).group_by(&:item_id)

    item_ids = (snapshot_quantities.keys + changes_by_item.keys).uniq
    names = @organization.items.where(id: item_ids).pluck(:id, :name).to_h

    rows = item_ids.filter_map do |item_id|
      row = build_row(item_id, names[item_id], snapshot_quantities.fetch(item_id, 0), changes_by_item.fetch(item_id, []),
        start_known: start_known)
      row unless row.empty?
    end.sort_by { |row| row.item_name.to_s.downcase }

    Result.new(rows: rows, totals: Row.total(rows, start_known: start_known),
      history_start: (history_start unless start_known))
  end

  private

  # The net change a record made to one item at this location.
  ItemChange = Data.define(:item_id, :time, :adjustment, :quantity)

  # Everything one record (e.g. a donation and all of its edits) changed at
  # this location, dated to when the record was first created.
  class RecordChanges
    def initialize(time:, adjustment:)
      @time = time
      @adjustment = adjustment
      @previous_item_ids = []
      @quantities = Hash.new(0)
    end

    # Records the items a new version of the record touches. An edit can
    # remove an item, so the items the previous version touched may have
    # changed too.
    # @param item_ids [Array<Integer>]
    # @return [Array<Integer>] the items this version or the previous one touched
    def touch(item_ids)
      touched = @previous_item_ids | item_ids
      @previous_item_ids = item_ids
      touched
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    def add(item_id, quantity)
      @quantities[item_id] += quantity
    end

    # @return [Array<ItemChange>]
    def item_changes
      @quantities.filter_map do |item_id, quantity|
        next if quantity.zero?

        ItemChange.new(item_id: item_id, time: @time, adjustment: @adjustment, quantity: quantity)
      end
    end
  end
  private_constant :ItemChange, :RecordChanges

  # Replays the inventory, totalling up the change each record made to each
  # item at this location.
  # @return [Array(Time, Hash<Integer, Integer>, Array<RecordChanges>)] when the
  #   snapshot the replay started from was taken (nil if there is none), the
  #   quantities at that snapshot, and each record's changes since
  def replay
    history_start = nil
    snapshot_quantities = {}
    quantities = Hash.new(0) # item_id => quantity after the last event
    records = {}

    InventoryAggregate.inventory_for(@organization.id) do |event, inventory|
      items = inventory.storage_locations[@storage_location.id]&.items || {}
      if event.is_a?(SnapshotEvent)
        history_start = event.event_time
        snapshot_quantities = items.transform_values(&:quantity)
        quantities = Hash.new(0).merge(snapshot_quantities)
        next
      end

      key = event.editable? ? [event.eventable_type, event.eventable_id] : [:event, event.id]
      record = records[key] ||= RecordChanges.new(time: event.event_time, adjustment: ADJUSTMENT_TYPES.any? { |type| event.is_a?(type) })
      record.touch(item_ids_here(event)).each do |item_id|
        quantity = items[item_id]&.quantity.to_i
        record.add(item_id, quantity - quantities[item_id])
        quantities[item_id] = quantity
      end
    end

    [history_start, snapshot_quantities, records.values]
  end

  # @return [Array<Integer>] the items the event moves into or out of this location
  def item_ids_here(event)
    event.data.items.filter_map do |line_item|
      line_item.item_id if [line_item.to_storage_location, line_item.from_storage_location].include?(@storage_location.id)
    end
  end

  # @param snapshot_quantity [Integer]
  # @param changes [Array<ItemChange>] the item's changes since the snapshot
  # @param start_known [Boolean]
  # @return [Row]
  def build_row(item_id, item_name, snapshot_quantity, changes, start_known:)
    quantity_start = snapshot_quantity + changes.select { |change| before?(change.time, @date_range&.begin) }.sum(&:quantity)
    during = changes.select { |change| in_range?(change.time) }
    adjustments, moves = during.partition(&:adjustment)
    ins, outs = moves.partition { |change| change.quantity.positive? }

    Row.new(
      item_id: item_id,
      item_name: item_name,
      quantity_start: (quantity_start if start_known),
      quantity_in: ins.sum(&:quantity),
      quantity_out: -outs.sum(&:quantity),
      quantity_adjustment: adjustments.sum(&:quantity),
      quantity_end: quantity_start + during.sum(&:quantity)
    )
  end

  # @return [Boolean] whether both times are known and the first is before the second
  def before?(time, other)
    !time.nil? && !other.nil? && time < other
  end

  def in_range?(time)
    @date_range.nil? || @date_range.cover?(time)
  end
end
