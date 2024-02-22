class HistoricalTrendService
  def initialize(organization_id, type)
    @organization = Organization.find(organization_id)
    @type = type
  end

  def series
    items_hash = {}
    month_offset = [*1..12].rotate(Time.zone.today.month)

    query
      .find_each do |item|
        items_hash[item.id] ||= {name: item.name, month_total: (1..12).index_with { |i| 0 }}
        items_hash[item.id][:month_total][month_offset.index(item.month_trunk.month) + 1] = item.total
      end

    items_hash.map do |id, item|
      {name: item[:name], data: item[:month_total].values, visible: false}
    end
  end

  private

  def query
    @organization
      .items
      .active
      .joins(:line_items)
      .where(line_items: {itemizable_type: @type,
                          created_at: 1.year.ago.beginning_of_month..Time.current}) # shouldnt it be `..Date.today.at_beginning_of_month`?
      .select(:id,
        :name,
        "DATE_TRUNC('month', line_items.created_at)::timestamptz as month_trunk",
        "SUM(quantity) as total")
      .group(:id, :name, :month_trunk)
      .order(:name)
  end
end
