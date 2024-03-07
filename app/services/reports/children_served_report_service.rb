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

    def disposable_diapers_from_kits_total
      organization_id = organization.id
      sql_query = <<-SQL
        SELECT SUM("line_items"."quantity" * "kit_line_items"."quantity")
        FROM "distributions" 
        INNER JOIN "line_items" ON "line_items"."itemizable_type" = 'Distribution' AND "line_items"."itemizable_id" = "distributions"."id" 
        INNER JOIN "items" ON "items"."id" = "line_items"."item_id" 
        INNER JOIN "kits" ON "kits"."id" = "items"."kit_id" 
        INNER JOIN "line_items" "kit_line_items" ON "kit_line_items"."itemizable_type" = 'Kit' AND "kit_line_items"."itemizable_id" = "kits"."id"
        INNER JOIN "items" "kit_items" ON "kit_items"."id" = "kit_line_items"."item_id"
        INNER JOIN "base_items" ON "base_items"."partner_key" = "kit_items"."partner_key" 
        WHERE "distributions"."organization_id" = #{organization_id}
          AND extract(year from issued_at) = #{@year}
          AND lower(base_items.category) LIKE '%diaper%'
          AND NOT (lower(base_items.category) LIKE '%cloth%' OR lower(base_items.name) LIKE '%cloth%')
      SQL

      result = ActiveRecord::Base.connection.execute(sql_query, [organization_id, @year])
      # Fetch the sum from the result set
      total = result.first['sum'].to_i
      total
    end

    private

    def total_disposable_diapers_distributed
      loose_disposable_distribution_total + disposable_diapers_from_kits_total
    end

    def loose_disposable_distribution_total
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.disposable)
      .sum("line_items.quantity")
    end

    # def disposable_diapers_from_kits_total
    #   organization
    #   .distributions
    #   .for_year(year)
    #   .joins(line_items: {item: :kit})
    #   .merge(Item.disposable)
    #   .where.not(items: {kit_id: nil})
    #   .sum("line_items.quantity")
    # end
    
    def total_children_served_with_loose_disposables
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.disposable)
      .sum('line_items.quantity / COALESCE(items.distribution_quantity, 50)')
    end

    def children_served_with_kits_containing_disposables
      organization
      .distributions
      .for_year(year)
      .joins(line_items: {item: :kit})
      .merge(Item.disposable)
      .where.not(items: {kit_id: nil})
      .distinct
      .count("kits.id")
    end
  end
end
