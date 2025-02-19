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
      .sum('line_items.quantity / COALESCE(items.distribution_quantity, 50)')
    end

    # These joins look circular but are needed due to polymorphic relationships.
    # A distribution has many line_items, items, and base_items but kits also
    # have the same relationships and we want to perform calculations on the
    # items in the kits not the kit items themselves.
    def children_served_with_kits_containing_disposables
      organization
        .distributions
        .for_year(year)
        .joins(line_items: { item: {kit: {line_items: {item: :base_item}}}})
        .merge(Item.disposable)
        .sum("line_items.quantity * line_items_kits.quantity / COALESCE(items_line_items.distribution_quantity, 50)")
    end
  end
end
