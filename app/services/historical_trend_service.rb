class HistoricalTrendService
  def initialize(organization_id, type)
    @organization = Organization.find(organization_id)
    @type = type
  end

  def series
    items = []

    @organization.items.active.sort.each do |item|
      next if item.line_items.where(itemizable_type: @type, item: item).blank?

      month_offset = [*1..12].rotate(Time.zone.today.month)

      dates = (1..12).index_with { |i| 0 }

      total_items(item.line_items, @type).each do |line_item|
        month = line_item.dig(0).to_date.month
        dates[(month_offset.index(month) + 1)] = line_item.dig(1)
      end

      items << {name: item.name, data: dates.values, visible: false}
    end

    items.sort_by { |hsh| hsh[:name] }
  end

  private

  def total_items(line_items, type)
    line_items.where(created_at: 1.year.ago.beginning_of_month..Time.current)
      .where(itemizable_type: type)
      .group_by_month(:created_at)
      .sum(:quantity)
  end
end
