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
      .merge(ConcreteItem.disposable_diapers)
      .pick(Arel.sql("CEILING(SUM(line_items.quantity::numeric / COALESCE(items.distribution_quantity, 50)))"))
      .to_i
    end

    # A distribution line item can reference a Kit. The kit's contents are its own
    # line items, so we join from the distributed Kit to its contents to find the kits that
    # contain disposable diapers, then count children served based on the kit's distribution_quantity.
    def children_served_with_kits_containing_disposables
      kits_subquery = organization
        .distributions
        .for_year(year)
        .joins(line_items: :item)
        .joins("INNER JOIN line_items kit_contents ON kit_contents.itemizable_type = 'Item' AND kit_contents.itemizable_id = items.id")
        .joins("INNER JOIN items kit_content_items ON kit_content_items.id = kit_contents.item_id")
        .where(items: { type: 'Kit' })
        .where("kit_content_items.reporting_category = 'disposable_diapers'")
        .select("DISTINCT ON (distributions.id, line_items.id, items.id) line_items.quantity, items.distribution_quantity")
        .to_sql

      Distribution
        .from("(#{kits_subquery}) AS q")
        .pick(Arel.sql("CEILING(SUM(q.quantity::numeric / COALESCE(q.distribution_quantity, 1)))"))
        .to_i
    end
  end
end
