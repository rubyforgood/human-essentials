class HistoricalTrendService
  def initialize(organization_id, type)
    @organization = Organization.find(organization_id)
    @type = type
  end

  def series
    # Preload line_items with a single query to avoid N+1 queries.
    items_with_line_items = @organization.items.active
      .includes(:line_items)
      .where(line_items: {itemizable_type: @type, created_at: 1.year.ago.beginning_of_month..Time.current})
      .order(:name)

    month_offset = [*1..12].rotate(Time.zone.today.month)
    default_dates = (1..12).index_with { |i| 0 }

    items_with_line_items.each_with_object([]) do |item, array_of_items|
      dates = default_dates.deep_dup

      item.line_items.each do |line_item|
        month = line_item.created_at.month
        index = month_offset.index(month) + 1
        dates[index] = dates[index] + line_item.quantity
      end

      array_of_items << {name: item.name, data: dates.values, visible: false} unless dates.values.sum.zero?
    end
  end
end
