# frozen_string_literal: true

class ItemsFlowQuery
  attr_reader :organization
  attr_reader :filter_params
  attr_reader :storage_location

  def initialize(organization:, storage_location:, filter_params: nil)
    @organization = organization
    @storage_location = storage_location
    @filter_params = filter_params
  end

  def call
    query = <<~SQL
      with events_with_flags as (
        select it.id as item_id,
          it.name as item_name,
          -- in quantity for this row (0 if not matching)
          case
            when (e.type = 'DonationEvent' and (item->>'to_storage_location')::int = :id)
              or (e.type = 'PurchaseEvent' and (item->>'to_storage_location')::int = :id)
              or (e.type = 'AdjustmentEvent' and (item->>'to_storage_location')::int = :id)
              or (e.type = 'TransferEvent' and (item->>'to_storage_location')::int = :id)
              or (e.type = 'AuditEvent' and (item->>'to_storage_location')::int = :id)
              and e.organization_id = :organization_id
            then (item->>'quantity')::int
            else 0
          end as quantity_in,
          -- out quantity normalized to positive numbers (0 if not matching)
          case
            when (e.type = 'DistributionEvent' and (item->>'from_storage_location')::int = :id)
              or (e.type = 'AdjustmentEvent' and (item->>'from_storage_location')::int = :id)      
              or (e.type = 'TransferEvent' and (item->>'from_storage_location')::int = :id)
              or (e.type = 'AuditEvent' and (item->>'from_storage_location')::int = :id)
              and e.organization_id = :organization_id
            then case when (item->>'quantity')::int < 0 then -(item->>'quantity')::int else (item->>'quantity')::int end
            else 0
          end as quantity_out,
          -- mark rows that are relevant for the overall WHERE in original query
          case
            when ( (e.type = 'DonationEvent' and (item->>'to_storage_location')::int = :id)
                or (e.type = 'PurchaseEvent' and (item->>'to_storage_location')::int = :id)
                or (e.type = 'DistributionEvent' and (item->>'from_storage_location')::int = :id)
                or (e.type = 'TransferEvent' and ((item->>'from_storage_location')::int = :id or (item->>'to_storage_location')::int = :id))
                or (e.type = 'AdjustmentEvent' and (item->>'from_storage_location')::int = :id or (item->>'to_storage_location')::int = :id)
              ) and e.organization_id = :organization_id
            then 1 else 0
          end as relevant
        from events e
          left join lateral jsonb_array_elements(data->'items') as item on true
          left join items it on it.id = (item->>'item_id')::int and it.organization_id = :organization_id
        where e.created_at >= :start_date and e.created_at <= :end_date
      )
      select
        item_id,
        item_name,
        sum(quantity_in) as quantity_in,
        sum(quantity_out) as quantity_out,
        sum(quantity_in) - sum(quantity_out) as change,
        sum(sum(quantity_in)) over () as total_quantity_in,
        sum(sum(quantity_out)) over () as total_quantity_out,
        sum(sum(quantity_in) - sum(quantity_out)) over () as total_change
      from events_with_flags
      where relevant = 1
      group by item_id, item_name
      order by item_name;
    SQL

    ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.send(:sanitize_sql_array, [query, {
        id: @storage_location.id,
        organization_id: @organization.id,
        start_date: @filter_params ? @filter_params[0] : 20.years.ago,
        end_date: @filter_params ? @filter_params[1] : Time.current.end_of_day
      }])
    )
  end
end
