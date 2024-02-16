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

    def disposable_diapers_from_kits_total
      organization
      .distributions
      .for_year(year)
      .joins(line_items: {item: :kit})
      .merge(Item.disposable)
      .where.not(items: {kit_id: nil})
      .sum("line_items.quantity")
    end

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
