class DistributionSummaryByCountyQuery
  DISTRIBUTION_BY_COUNTY_SQL = <<~SQL.squish.freeze
    /* Calculate total item quantity and value per distribution */
    WITH distribution_totals AS
    (
        SELECT DISTINCT d.id,
                        d.partner_id,
                        COALESCE(SUM(li.quantity) OVER (PARTITION BY d.id), 0) AS quantity,
                        COALESCE(SUM(COALESCE(i.value_in_cents, 0) * li.quantity) OVER (PARTITION BY d.id), 0) AS amount
        FROM distributions d
        JOIN line_items li ON li.itemizable_id = d.id AND li.itemizable_type = 'Distribution'
        JOIN items i ON i.id = li.item_id
        WHERE d.issued_at BETWEEN :start_date AND :end_date
            AND d.organization_id = :organization_id
        GROUP BY d.id, li.id, i.id
    ),
    /* Match distribution totals with client share and counties.
       If distribution has no associated county, set county name to "Unspecified"
       and set region to ZZZ so it will be last when sorted  */
    totals_by_county AS
    (
        SELECT dt.id,
               dt.quantity,
               dt.amount,
               COALESCE(psa.client_share::float / 100, 1) AS percentage,
               COALESCE(c.name, 'Unspecified') county_name,
               COALESCE(c.region, 'ZZZ') county_region
        FROM distribution_totals dt
        LEFT JOIN partner_profiles pp ON pp.id = dt.partner_id
        LEFT JOIN partner_served_areas psa ON psa.partner_profile_id = pp.partner_id
        LEFT JOIN counties c ON c.id = psa.county_id
        UNION
        /* Previous behavior was to add a row for unspecified counties
           even if all distributions have an associated county */
        SELECT 0 AS id,
               0 AS quantity,
               0 AS amount,
               1 AS percentage,
               'Unspecified' AS county_name,
               'ZZZ' AS county_region
    )
    /* Distribution value and quantities per county share may not be whole numbers,
       so we cast to an integer for rounding purposes */
    SELECT tbc.county_name AS name,
           SUM((tbc.quantity * percentage)::int) AS quantity,
           SUM((tbc.amount * percentage)::int) AS amount
    FROM totals_by_county tbc
    GROUP BY county_name, county_region
    ORDER BY county_region ASC;
  SQL

  def initialize(organization_id:, start_date: nil, end_date: nil)
    @organization_id = organization_id
    @start_date = start_date || "1000-01-01"
    @end_date = end_date || "3000-01-01"
  end

  def call
    execute(to_sql(DISTRIBUTION_BY_COUNTY_SQL)).to_a
  end

  private

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def to_sql(query)
    ActiveRecord::Base.sanitize_sql_array(
      [
        query,
        organization_id: @organization_id,
        start_date: @start_date,
        end_date: @end_date
      ]
    )
  end
end
