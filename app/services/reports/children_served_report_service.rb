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
                      'Diapers per child monthly' => number_with_delimiter(per_child_monthly.round),
                      'Repackages diapers?' => organization.repackage_essentials? ? 'Y' : 'N',
                      'Monthly diaper distributions?' => organization.distribute_monthly? ? 'Y' : 'N'
                    } }
    end

    # @return [Integer]
    def total_children_served
      @total_children_served ||= organization
                                 .distributions
                                 .for_year(year)
                                 .joins(line_items: :item)
                                 .merge(Item.disposable)
                                 .sum('line_items.quantity / COALESCE(items.distribution_quantity, 50)') || 0
    end

    # @return [Float]
    def average_children_monthly
      total_children_served / 12.0
    end

    # @return [Float]
    def per_child_monthly
      organization
        .distributions
        .for_year(year)
        .joins(line_items: :item)
        .merge(Item.disposable)
        .average('COALESCE(items.distribution_quantity, 50)') || 0.0
    end
  end
end
