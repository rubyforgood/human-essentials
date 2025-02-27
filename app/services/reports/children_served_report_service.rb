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
                      'Average children served monthly' => number_with_delimiter(average_children_monthly),
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
      (total_children_served / 12.0).round(2)
    end

    private

    def total_children_served_with_loose_disposables
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.loose.disposable)
      .pick(Arel.sql("CEILING(SUM(line_items.quantity::numeric / COALESCE(items.distribution_quantity, 50)))"))
      .to_i
    end

    # These joins look circular but are needed due to polymorphic relationships.
    # A distribution has many line_items, items, and base_items but kits also
    # have the same relationships and we want to perform calculations on the
    # items in the kits not the kit items themselves.
    def children_served_with_kits_containing_disposables
      organization
        .distributions
        .for_year(year)
        .joins(line_items: { item: { kit: { line_items: {item: :base_item} }}})
        .where("base_items.category ILIKE '%diaper%' AND
          NOT base_items.category ILIKE '%cloth%' OR base_items.name ILIKE '%cloth%' AND
          NOT base_items.category ILIKE '%adult%'")
        .group("line_items_kits.id")
        .pick(Arel.sql("CEILING(SUM(line_items.quantity::numeric / COALESCE(items.distribution_quantity, 1)))"))
        .to_i
    end
  end
end
