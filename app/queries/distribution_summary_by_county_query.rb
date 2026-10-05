class DistributionSummaryByCountyQuery
  CountySummary = Data.define(:name, :quantity, :value)

  # No need to send comments in the query
  SQL_MULTILINE_COMMENTS = /\/\*.*?\*\//

  DISTRIBUTION_BY_COUNTY_SQL = <<~SQL.squish.gsub(SQL_MULTILINE_COMMENTS, "").freeze
    /* Calculate total item quantity and value per distribution of "loose" items */

    WITH loose_distribution_totals AS
    (
        SELECT DISTINCT d.id,
                        d.partner_id,
                        COALESCE(SUM(li.quantity) OVER (PARTITION BY d.id), 0) AS quantity,
                        COALESCE(SUM(COALESCE(i.value_in_cents, 0) * li.quantity) OVER (PARTITION BY d.id), 0) AS value
        FROM distributions d
        JOIN line_items li ON li.itemizable_id = d.id AND li.itemizable_type = 'Distribution'
        JOIN items i ON i.id = li.item_id
        WHERE d.issued_at BETWEEN :start_date AND :end_date
            AND d.organization_id = :organization_id
            AND i.reporting_category LIKE CONCAT('%', :reporting_category , '%')
            AND i.id = CASE WHEN :item_id <> 0 THEN :item_id ELSE i.id END
        GROUP BY d.id, li.id, i.id
    ),
    /* Calculate total item and value per distribution of items that happen to be in kits */
       kitted_distribution_totals AS (
       SELECT DISTINCT d.id,
                        d.partner_id,
                        COALESCE(SUM(li.quantity * kli.quantity) OVER (PARTITION BY d.id), 0) AS quantity,
                        COALESCE(SUM(COALESCE(ki.value_in_cents, 0) * li.quantity * kli.quantity) OVER (PARTITION BY d.id), 0) AS value
        FROM distributions d
        INNER JOIN line_items li ON li.itemizable_id = d.id AND li.itemizable_type = 'Distribution'
        INNER JOIN items i ON i.id = li.item_id
        INNER JOIN line_items AS kli ON i.id = kli.itemizable_id AND kli.itemizable_type = 'Item'
        INNER JOIN items AS ki ON ki.id = kli.item_id
                                 WHERE d.issued_at BETWEEN :start_date AND :end_date
            AND d.organization_id = :organization_id
            AND ki.reporting_category LIKE CONCAT('%', :reporting_category , '%')
            AND ki.id = CASE WHEN :item_id <> 0 THEN :item_id ELSE ki.id END
        GROUP BY d.id, li.id, i.id, kli.id, ki.id
        ),   
        
            /* Combine the loose and kitted */
        full_distribution_totals as (
            SELECT distinct COALESCE(ld.id,kd.id) as id, 
                COALESCE(ld.partner_id, kd.partner_id) AS partner_id, 
                 COALESCE(ld.quantity,0) + COALESCE(kd.quantity, 0) as quantity, 
                 COALESCE(ld.value,0) + COALESCE(kd.value, 0)  as value
                FROM loose_distribution_totals ld 
                FULL OUTER JOIN kitted_distribution_totals kd ON ld.id = kd.id 
        ),
                 
    /* Match full distribution totals with client share and counties.
       If distribution has no associated county, set county name to "Unspecified"
       and set region to ZZZ so it will be last when sorted  */
    totals_by_county AS
    (
        SELECT dt.id,
               dt.quantity,
               dt.value,
               COALESCE(psa.client_share::float / 100, 1) AS percentage,
               COALESCE(c.name, 'Unspecified') county_name,
               COALESCE(c.region, 'ZZZ') county_region
        FROM full_distribution_totals dt
        LEFT JOIN partners p ON p.id = dt.partner_id
        LEFT JOIN partner_profiles pp ON pp.partner_id = p.id
        LEFT JOIN partner_served_areas psa ON psa.partner_profile_id = pp.id
        LEFT JOIN counties c ON c.id = psa.county_id
        UNION
        /* Previous behavior was to add a row for unspecified counties
           even if all distributions have an associated county */
        SELECT 0 AS id,
               0 AS quantity,
               0 AS value,
               1 AS percentage,
               'Unspecified' AS county_name,
               'ZZZ' AS county_region
    )
    /* Distribution value and quantities per county share may not be whole numbers,
       so we cast to an integer for rounding purposes */
    SELECT tbc.county_name AS name,
           SUM((tbc.quantity * percentage)::int) AS quantity,
           SUM((tbc.value * percentage)::int) AS value
    FROM totals_by_county tbc
    GROUP BY county_name, county_region
    ORDER BY county_region ASC;
  SQL

  class << self
    # Timestamps are stored in Postgres without timezones so
    # start_date and end_date must be strings in UTC.
    def call(organization_id:, start_date: nil, end_date: nil, reporting_category: nil, item_id: nil)
      params = {
        organization_id: organization_id,
        start_date: start_date || "1000-01-01",
        end_date: end_date || "3000-01-01",
        reporting_category: reporting_category,
        item_id: item_id
      }

      execute(to_sql(DISTRIBUTION_BY_COUNTY_SQL, **params)).to_a.map(&to_county_summary)
    end

    private

    def execute(sql)
      ActiveRecord::Base.connection.execute(sql)
    end

    def to_sql(query, organization_id:, start_date:, end_date:, reporting_category:, item_id:)
      ActiveRecord::Base.sanitize_sql_array(
        [
          query,
          organization_id: organization_id,
          start_date: start_date,
          end_date: end_date,
          reporting_category: reporting_category,
          item_id: item_id
        ]
      )
    end

    def to_county_summary
      ->(params) { CountySummary.new(**params) }
    end
  end
end
