module Reports
  class ChildrenServedReportService
    include ActionView::Helpers::NumberHelper
    attr_reader :year, :organization

    # @param year [Integer]
    # @param organization [Organization]
    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    # @return [Hash]
    def report
      @report ||= { name: 'Children Served',
                    entries: {
                      'Average children served monthly' => number_with_delimiter(average_children_monthly.round),
                      'Total children served' => number_with_delimiter(total_children_served),
                      'Repackages diapers?' => organization.repackage_essentials? ? 'Y' : 'N',
                      'Monthly diaper distributions?' => organization.distribute_monthly? ? 'Y' : 'N'
                    } }
    end

    # @return [Integer]
    def total_children_served
      @total_children_served ||= total_children_served_with_loose_disposables + children_served_with_kits_containing_disposables
    end

    # @return [Float]
    def average_children_monthly
      total_children_served / 12.0
    end

    private

    def total_children_served_with_loose_disposables
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.disposable)
      .sum('line_items.quantity / COALESCE(items.distribution_quantity, 50)') # if item.default_quantity changes, this should change too
    end

    def children_served_with_kits_containing_disposables
      organization_id = @organization.id
      year = @year

      # SUM assumes 1 person per kit, this will be changed by #4542
      # if item.default_quantity changes, COALESCE(items_in_kit.distribution_quantity, 50) should change too
      sql_query = <<-SQL
      SELECT SUM((line_items.quantity * kit_line_items.quantity) / CAST(COALESCE(items_in_kit.distribution_quantity, 50) AS DECIMAL))
      FROM distributions
      INNER JOIN line_items ON line_items.itemizable_type = 'Distribution' AND line_items.itemizable_id = distributions.id
      INNER JOIN items AS items_housing_a_kit ON items_housing_a_kit.id = line_items.item_id AND items_housing_a_kit.kit_id IS NOT NULL
      INNER JOIN line_items AS kit_line_items ON kit_line_items.itemizable_id = items_housing_a_kit.id AND kit_line_items.itemizable_type = 'Item'
      INNER JOIN items AS items_in_kit ON items_in_kit.id = kit_line_items.item_id
      INNER JOIN base_items AS base_items_in_kit ON base_items_in_kit.partner_key = items_in_kit.partner_key
      WHERE distributions.organization_id = ?
        AND EXTRACT(year FROM issued_at) = ?
        AND LOWER(base_items_in_kit.category) LIKE '%diaper%'
        AND NOT (((LOWER(base_items_in_kit.category) LIKE '%cloth%') OR (LOWER(base_items_in_kit.name) LIKE '%cloth%')))
        AND NOT (LOWER(base_items_in_kit.category) LIKE '%adult%')
      SQL
      # TODO duplicated code from Item.disposable scope, and AcquisitionReportService. merge when working on #3652
      sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql_query, organization_id, year])
      result = ActiveRecord::Base.connection.execute(sanitized_sql)
      result.first['sum'].to_f.ceil
    end
  end
end
