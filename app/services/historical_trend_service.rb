class HistoricalTrendService
  def initialize(organization_id, type)
    @organization = Organization.find(organization_id)
    @type = type
  end

  # Returns: [{:name=>"Adult Briefs (XXL)", :data=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 416, 0, 0], :visible=>false}]
  # :data contains quantity from 11 months ago to current month
  def series
    type_symbol = @type.tableize.to_sym # :distributions, :donations, :purchases
    records_for_type = @organization.send(type_symbol)
      .includes(items: :line_items)
      .where(issued_at: 1.year.ago.beginning_of_month..Time.current)

    array_of_items = []

    records_for_type.each do |record|
      index = record.issued_at.month - Date.current.month - 1

      record.line_items.each do |line_item|
        name = line_item.item.name
        quantity = line_item.quantity
        next if quantity.zero?

        if (existing_item = array_of_items.find { |item| item[:name] == name })
          quantity_per_month = existing_item[:data]
          quantity_per_month[index] += quantity
        else
          quantity_per_month = Array.new(12, 0)
          quantity_per_month[index] += quantity
          array_of_items << {name:, data: quantity_per_month, visible: false}
        end
      end
    end

    array_of_items.sort_by { |item| item[:name] }
  end
end
