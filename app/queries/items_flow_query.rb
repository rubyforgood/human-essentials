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
# handles them) and total up the net change each record made to each item at
# this location, dated to when the record was first created. Records from
# before the range make up the start quantity and records within it make up
# the in, out and adjustment columns, so start + change always equals end.
class ItemsFlowQuery
  Result = Data.define(:rows, :totals)

  # How one item's quantity moved over the date range. The totals row has no
  # item.
  Row = Data.define(:item_id, :item_name, :quantity_start, :quantity_in, :quantity_out, :quantity_adjustment) do
    # @param rows [Array<Row>]
    # @return [Row]
    def self.total(rows)
      new(
        item_id: nil,
        item_name: nil,
        quantity_start: rows.sum(&:quantity_start),
        quantity_in: rows.sum(&:quantity_in),
        quantity_out: rows.sum(&:quantity_out),
        quantity_adjustment: rows.sum(&:quantity_adjustment)
      )
    end

    def change
      quantity_in - quantity_out + quantity_adjustment
    end

    def quantity_end
      quantity_start + change
    end

    def empty?
      [quantity_start, quantity_in, quantity_out, quantity_adjustment].all?(&:zero?)
    end
  end

  ADJUSTMENT_TYPES = %w[AdjustmentEvent AuditEvent].freeze

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
    snapshot_quantities, records = replay
    changes_by_item = records.flat_map(&:item_changes).group_by(&:item_id)

    item_ids = (snapshot_quantities.keys + changes_by_item.keys).uniq
    names = Item.where(id: item_ids).pluck(:id, :name).to_h

    rows = item_ids.filter_map do |item_id|
      row = build_row(item_id, names[item_id], snapshot_quantities.fetch(item_id, 0), changes_by_item.fetch(item_id, []))
      row unless row.empty?
    end.sort_by { |row| row.item_name.to_s }

    Result.new(rows: rows, totals: Row.total(rows))
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
  # @return [Array(Hash<Integer, Integer>, Array<RecordChanges>)] quantities at
  #   the snapshot the replay started from, and each record's changes since
  def replay
    snapshot_quantities = {}
    quantities = Hash.new(0) # item_id => quantity after the last event
    records = {}

    InventoryAggregate.inventory_for(@organization.id) do |event, inventory|
      items = inventory.storage_locations[@storage_location.id]&.items || {}
      if event.is_a?(SnapshotEvent)
        snapshot_quantities = items.transform_values(&:quantity)
        quantities = Hash.new(0).merge(snapshot_quantities)
        next
      end

      key = event.is_edit? ? [event.eventable_type, event.eventable_id] : [:event, event.id]
      record = records[key] ||= RecordChanges.new(time: event.event_time, adjustment: ADJUSTMENT_TYPES.include?(event.type))
      record.touch(item_ids_here(event)).each do |item_id|
        quantity = items[item_id]&.quantity.to_i
        record.add(item_id, quantity - quantities[item_id])
        quantities[item_id] = quantity
      end
    end

    [snapshot_quantities, records.values]
  end

  # @return [Array<Integer>] the items the event moves into or out of this location
  def item_ids_here(event)
    event.data.items.filter_map do |line_item|
      line_item.item_id if [line_item.to_storage_location, line_item.from_storage_location].include?(@storage_location.id)
    end
  end

  # @param snapshot_quantity [Integer]
  # @param changes [Array<ItemChange>] the item's changes since the snapshot
  # @return [Row]
  def build_row(item_id, item_name, snapshot_quantity, changes)
    before = changes.select { |change| before_range?(change.time) }
    adjustments, moves = changes.select { |change| in_range?(change.time) }.partition(&:adjustment)
    ins, outs = moves.partition { |change| change.quantity.positive? }

    Row.new(
      item_id: item_id,
      item_name: item_name,
      quantity_start: snapshot_quantity + before.sum(&:quantity),
      quantity_in: ins.sum(&:quantity),
      quantity_out: -outs.sum(&:quantity),
      quantity_adjustment: adjustments.sum(&:quantity)
    )
  end

  def before_range?(time)
    !@date_range.nil? && time < @date_range.begin
  end

  def in_range?(time)
    @date_range.nil? || @date_range.cover?(time)
  end
end
