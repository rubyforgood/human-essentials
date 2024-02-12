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
      @total_children_served ||= total_children_served_with_loose_disposable + distributed_kits_with_disposable_items
    end

    # @return [Float]
    def average_children_monthly
      total_children_served / 12.0
    end

    # @return [Float]
    def per_child_monthly
      total_distributions = organization.distributions.for_year(year).count
      total_kits = organization.kits.count

      total_avg = if total_distributions.zero? && total_kits.zero?
        0.0
      else
        (loose_disposable_distribution_average * total_distributions + kit_average * total_kits) / (total_distributions + total_kits)
      end

      total_avg.nan? ? 0.0 : total_avg
    end

    private

    def loose_disposable_distribution_average
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.disposable)
      .average('COALESCE(items.distribution_quantity, 50)') || 0.0
    end

    def kit_average
      organization
      .kits
      .joins(inventory_items: :item)
      .merge(Item.disposable)
      .average('COALESCE(inventory_items.quantity, 0)') || 0.0
    end

    def total_children_served_with_loose_disposable
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.disposable)
      .sum('line_items.quantity / COALESCE(items.distribution_quantity, 50)')
    end

    def distributed_kits_with_disposable_items
      organization
      .distributions
      .for_year(year)
      .joins(line_items: :item)
      .merge(Item.disposable)
      .where.not(kit_id: nil)
      .distinct
      .count("kit_id")
    end
  end
end
