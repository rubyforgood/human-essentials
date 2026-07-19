# frozen_string_literal: true

class ItemsFlowQuery
  attr_reader :organization
  attr_reader :filter_params
  attr_reader :storage_location

  # Event types where editing the record republishes the full event for the
  # same eventable and inventory replay diffs against the previous version
  # (see InventoryAggregate). For flow purposes only the latest version per
  # eventable counts. Destroy events publish zeroed line items, so destroyed
  # records net out to nothing.
  VERSIONED_EVENT_TYPES = %w[
    DonationEvent PurchaseEvent DistributionEvent TransferEvent AdjustmentEvent
    DonationDestroyEvent PurchaseDestroyEvent DistributionDestroyEvent
    TransferDestroyEvent UpdateExistingEvent
  ].freeze

  # Event types where every event stands alone and applies in full
  # ("ignore previous events" in InventoryAggregate).
  #
  # AuditEvent deliberately appears in neither list: audit payloads store the
  # absolute counted quantity rather than a movement, so their flow
  # contribution can't be summed in SQL - see #apply_audit_deltas, which
  # derives each audit's delta by replaying the event log. Adding AuditEvent
  # here would double-count it.
  STANDALONE_EVENT_TYPES = %w[KitAllocateEvent KitDeallocateEvent].freeze

  def initialize(organization:, storage_location:, filter_params: nil)
    @organization = organization
    @storage_location = storage_location
    @filter_params = filter_params
  end

  def call
    flows = sql_flows
    apply_audit_deltas(flows)

    rows = flows.filter_map do |item_id, flow|
      next if flow[:in].zero? && flow[:out].zero?

      {
        "item_id" => item_id,
        "item_name" => flow[:name],
        "quantity_in" => flow[:in],
        "quantity_out" => flow[:out],
        "change" => flow[:in] - flow[:out]
      }
    end
    rows.sort_by! { |row| row["item_name"].to_s }

    total_in = rows.sum { |row| row["quantity_in"] }
    total_out = rows.sum { |row| row["quantity_out"] }
    rows.each do |row|
      row["total_quantity_in"] = total_in
      row["total_quantity_out"] = total_out
      row["total_change"] = total_in - total_out
    end

    rows
  end

  private

  def start_date
    @filter_params ? @filter_params[0] : 20.years.ago
  end

  def end_date
    @filter_params ? @filter_params[1] : Time.current.end_of_day
  end

  # @return [Hash<Integer, Hash>] item_id => {name:, in:, out:}
  def sql_flows
    query = <<~SQL
      with latest_versioned_events as (
        select distinct on (eventable_type, eventable_id) *
        from events
        where organization_id = :organization_id
          and type in (:versioned_types)
        order by eventable_type, eventable_id, updated_at desc
      ),
      flow_events as (
        select id, data from latest_versioned_events
        where event_time >= :start_date and event_time <= :end_date
        union all
        select id, data from events
        where organization_id = :organization_id
          and type in (:standalone_types)
          and event_time >= :start_date and event_time <= :end_date
      ),
      item_flows as (
        select it.id as item_id,
          it.name as item_name,
          case when (item->>'to_storage_location')::int = :id
            then (item->>'quantity')::int
            else 0
          end as quantity_in,
          -- out quantities normalized to positive numbers
          case when (item->>'from_storage_location')::int = :id
            then abs((item->>'quantity')::int)
            else 0
          end as quantity_out
        from flow_events e
          join lateral jsonb_array_elements(e.data->'items') as item on true
          left join items it on it.id = (item->>'item_id')::int and it.organization_id = :organization_id
        where (item->>'to_storage_location')::int = :id
          or (item->>'from_storage_location')::int = :id
      )
      select
        item_id,
        item_name,
        sum(quantity_in) as quantity_in,
        sum(quantity_out) as quantity_out
      from item_flows
      group by item_id, item_name
    SQL

    result = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.send(:sanitize_sql_array, [query, {
        id: @storage_location.id,
        organization_id: @organization.id,
        versioned_types: VERSIONED_EVENT_TYPES,
        standalone_types: STANDALONE_EVENT_TYPES,
        start_date: start_date,
        end_date: end_date
      }])
    )

    result.each_with_object({}) do |row, flows|
      flows[row["item_id"]] = {
        name: row["item_name"],
        in: row["quantity_in"].to_i,
        out: row["quantity_out"].to_i
      }
    end
  end

  # Audits record the absolute counted quantity, not a delta, so their flow
  # contribution is (counted quantity - quantity just before the audit).
  # Replay the event log once, tracking the audited items' quantities at this
  # location, to turn each in-range audit into a delta.
  def apply_audit_deltas(flows)
    audits = AuditEvent.where(organization_id: @organization.id, event_time: start_date..end_date)
    audited_item_ids = audits.flat_map { |audit| audit.data.items.map(&:item_id) }.uniq
    return if audited_item_ids.empty?

    audit_ids = audits.map(&:id).to_set
    quantities_before = Hash.new(0)

    InventoryAggregate.inventory_for(@organization.id) do |event, inventory|
      if audit_ids.include?(event.id)
        event.data.items.each do |line_item|
          next unless line_item.to_storage_location == @storage_location.id

          delta = line_item.quantity - quantities_before[line_item.item_id]
          flow = flows[line_item.item_id] ||= {name: Item.find_by(id: line_item.item_id)&.name, in: 0, out: 0}
          if delta.positive?
            flow[:in] += delta
          else
            flow[:out] += delta.abs
          end
        end
      end

      location = inventory.storage_locations[@storage_location.id]
      audited_item_ids.each do |item_id|
        quantities_before[item_id] = location&.items&.[](item_id)&.quantity.to_i
      end
    end
  end
end
