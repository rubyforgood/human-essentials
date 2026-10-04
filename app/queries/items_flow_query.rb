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
  # contribution can't be summed in SQL - see the replay in #call, which
  # derives each audit's delta from the running quantities. Adding AuditEvent
  # here would double-count it.
  STANDALONE_EVENT_TYPES = %w[KitAllocateEvent KitDeallocateEvent].freeze

  def initialize(organization:, storage_location:, filter_params: nil)
    @organization = organization
    @storage_location = storage_location
    @filter_params = filter_params
  end

  def call
    flows = sql_flows
    start_quantities = quantities_at(start_cutoff)
    end_quantities = apply_audit_deltas_and_end_quantities(flows)

    item_ids = (flows.keys + start_quantities.keys + end_quantities.keys).uniq
    names = Item.where(id: item_ids).pluck(:id, :name).to_h

    rows = item_ids.filter_map do |item_id|
      flow = flows[item_id] || {in: 0, out: 0, adjustment: 0}
      start_qty = start_quantities[item_id] || 0
      end_qty = end_quantities[item_id] || 0
      next if flow[:in].zero? && flow[:out].zero? && flow[:adjustment].zero? && start_qty == end_qty

      {
        "item_id" => item_id,
        "item_name" => flow[:name] || names[item_id],
        "quantity_start" => start_qty,
        "quantity_in" => flow[:in],
        "quantity_out" => flow[:out],
        "quantity_adjustment" => flow[:adjustment],
        "change" => flow[:in] - flow[:out] + flow[:adjustment],
        "quantity_end" => end_qty
      }
    end
    rows.sort_by! { |row| row["item_name"].to_s }

    totals = {
      "total_quantity_start" => rows.sum { |row| row["quantity_start"] },
      "total_quantity_in" => rows.sum { |row| row["quantity_in"] },
      "total_quantity_out" => rows.sum { |row| row["quantity_out"] },
      "total_quantity_adjustment" => rows.sum { |row| row["quantity_adjustment"] },
      "total_change" => rows.sum { |row| row["change"] },
      "total_quantity_end" => rows.sum { |row| row["quantity_end"] }
    }
    rows.each { |row| row.merge!(totals) }

    rows
  end

  private

  # Inventory state can only be derived back to the most recent usable
  # snapshot, so the effective window starts no earlier than just after it.
  def start_cutoff
    @start_cutoff ||= begin
      requested = @filter_params ? @filter_params[0] : 20.years.ago
      snapshot = Event.most_recent_snapshot(@organization.id)
      if snapshot && requested <= snapshot.event_time
        snapshot.event_time + 1.second
      else
        requested
      end
    end
  end

  def end_cutoff
    @end_cutoff ||= begin
      requested = @filter_params ? @filter_params[1] : Time.current.end_of_day
      [requested, start_cutoff].max
    end
  end

  # @return [Hash<Integer, Integer>] item_id => quantity at this location
  def quantities_at(event_time)
    inventory = InventoryAggregate.inventory_for(@organization.id, event_time: event_time)
    location_quantities(inventory)
  end

  def location_quantities(inventory)
    items = inventory.storage_locations[@storage_location.id]&.items || {}
    items.transform_values(&:quantity).reject { |_, quantity| quantity.zero? }
  end

  # Audits record the absolute counted quantity, not a delta, so their flow
  # contribution is (counted quantity - quantity just before the audit).
  # Replay the event log once up to the window end, tracking the audited
  # items' running quantities at this location to turn each in-range audit
  # into a delta; the same replay's final state is the window-end inventory.
  # @return [Hash<Integer, Integer>] item_id => quantity at the window end
  def apply_audit_deltas_and_end_quantities(flows)
    audits = AuditEvent.where(organization_id: @organization.id, event_time: start_cutoff..end_cutoff)
    audited_item_ids = audits.flat_map { |audit| audit.data.items.map(&:item_id) }.uniq
    audit_ids = audits.map(&:id).to_set
    quantities_before = Hash.new(0)

    # The aggregate only applies an event_time cutoff that is after the last
    # snapshot; when the window ends now-ish, replay without a cutoff.
    cutoff = (end_cutoff >= Time.current) ? nil : end_cutoff
    final_inventory = InventoryAggregate.inventory_for(@organization.id, event_time: cutoff) do |event, inventory|
      next if audited_item_ids.empty?

      if audit_ids.include?(event.id)
        event.data.items.each do |line_item|
          next unless line_item.to_storage_location == @storage_location.id

          delta = line_item.quantity - quantities_before[line_item.item_id]
          flow = flows[line_item.item_id] ||= {name: nil, in: 0, out: 0, adjustment: 0}
          flow[:adjustment] += delta
        end
      end

      location = inventory.storage_locations[@storage_location.id]
      audited_item_ids.each do |item_id|
        quantities_before[item_id] = location&.items&.[](item_id)&.quantity.to_i
      end
    end

    location_quantities(final_inventory)
  end

  # @return [Hash<Integer, Hash>] item_id => {name:, in:, out:, adjustment:}
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
        select id, type, data from latest_versioned_events
        where event_time > :start_date and event_time <= :end_date
        union all
        select id, type, data from events
        where organization_id = :organization_id
          and type in (:standalone_types)
          and event_time > :start_date and event_time <= :end_date
      ),
      item_flows as (
        select it.id as item_id,
          it.name as item_name,
          case when e.type != 'AdjustmentEvent' and (item->>'to_storage_location')::int = :id
            then (item->>'quantity')::int
            else 0
          end as quantity_in,
          -- out quantities normalized to positive numbers
          case when e.type != 'AdjustmentEvent' and (item->>'from_storage_location')::int = :id
            then abs((item->>'quantity')::int)
            else 0
          end as quantity_out,
          -- adjustments carry signed quantities; net them into their own column
          case when e.type = 'AdjustmentEvent'
            then case when (item->>'to_storage_location')::int = :id then (item->>'quantity')::int else 0 end
              - case when (item->>'from_storage_location')::int = :id then (item->>'quantity')::int else 0 end
            else 0
          end as quantity_adjustment
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
        sum(quantity_out) as quantity_out,
        sum(quantity_adjustment) as quantity_adjustment
      from item_flows
      group by item_id, item_name
    SQL

    result = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.send(:sanitize_sql_array, [query, {
        id: @storage_location.id,
        organization_id: @organization.id,
        versioned_types: VERSIONED_EVENT_TYPES,
        standalone_types: STANDALONE_EVENT_TYPES,
        start_date: start_cutoff,
        end_date: end_cutoff
      }])
    )

    result.each_with_object({}) do |row, flows|
      flows[row["item_id"]] = {
        name: row["item_name"],
        in: row["quantity_in"].to_i,
        out: row["quantity_out"].to_i,
        adjustment: row["quantity_adjustment"].to_i
      }
    end
  end
end
