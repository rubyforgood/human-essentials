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
      WITH line_items_with_flags AS (
        SELECT
          li.item_id,
          it.name AS item_name,
          -- in quantity for this row (0 if not matching)
          CASE
            WHEN (donations.storage_location_id = :id
                  OR purchases.storage_location_id = :id
                  OR (adjustments.storage_location_id = :id AND li.quantity > 0)
                  OR transfers.to_id = :id)
                 AND it.organization_id = :organization_id
            THEN li.quantity
            ELSE 0
          END AS quantity_in,
          -- out quantity normalized to positive numbers (0 if not matching)
          CASE
            WHEN (distributions.storage_location_id = :id
                  OR (adjustments.storage_location_id = :id AND li.quantity < 0)
                  OR transfers.from_id = :id)
                 AND it.organization_id = :organization_id
            THEN CASE WHEN li.quantity < 0 THEN -li.quantity ELSE li.quantity END
            ELSE 0
          END AS quantity_out,
          -- mark rows that are relevant for the overall WHERE in original query
          CASE
            WHEN (donations.storage_location_id = :id
                  OR purchases.storage_location_id = :id
                  OR distributions.storage_location_id = :id
                  OR transfers.from_id = :id
                  OR transfers.to_id = :id
                  OR adjustments.storage_location_id = :id)
                 AND it.organization_id = :organization_id
            THEN 1 ELSE 0
          END AS relevant
        FROM line_items li
        LEFT JOIN donations ON donations.id = li.itemizable_id AND li.itemizable_type = 'Donation'
        LEFT JOIN purchases ON purchases.id = li.itemizable_id AND li.itemizable_type = 'Purchase'
        LEFT JOIN distributions ON distributions.id = li.itemizable_id AND li.itemizable_type = 'Distribution'
        LEFT JOIN adjustments ON adjustments.id = li.itemizable_id AND li.itemizable_type = 'Adjustment'
        LEFT JOIN transfers ON transfers.id = li.itemizable_id AND li.itemizable_type = 'Transfer'
        LEFT JOIN items it ON it.id = li.item_id
        WHERE li.created_at >= :start_date AND li.created_at <= :end_date
      )
      SELECT
        item_id,
        item_name,
        SUM(quantity_in)   AS quantity_in,
        SUM(quantity_out)  AS quantity_out,
        SUM(quantity_in) - SUM(quantity_out) AS change,
        SUM(SUM(quantity_in)) OVER () AS total_quantity_in,
        SUM(SUM(quantity_out)) OVER () AS total_quantity_out,
        SUM(SUM(quantity_in) - SUM(quantity_out)) OVER () AS total_change
      FROM line_items_with_flags
      WHERE relevant = 1
      GROUP BY item_id, item_name
      ORDER BY item_name;
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
