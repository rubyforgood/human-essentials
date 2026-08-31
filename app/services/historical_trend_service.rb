class HistoricalTrendService
  # The window, as whole months. `from` and `to` are any date inside the first and last month
  # wanted; they are snapped to month boundaries here so a caller cannot hand in a partial one.
  #
  # A month is the bucket, so a month is the unit the window is expressed in -- see "A period chart
  # takes a period range" in design.md. The picker only offers months for the same reason.
  def initialize(organization_id, type, from: nil, to: nil, category_id: nil)
    @organization = Organization.find(organization_id)
    @type = type
    # nil is every category; "none" is the items that have none. Both are real answers -- 16 of the
    # 51 items here are uncategorised, so an "Uncategorised" option is not an edge case.
    @category_id = category_id.presence
    @to = (to || Time.zone.today).to_date.end_of_month
    @from = (from || (@to - 11.months)).to_date.beginning_of_month
    @from = @to.beginning_of_month if @from > @to
  end

  attr_reader :from, :to, :category_id

  # The months in the window, oldest first, as Date objects on the first of each.
  def months
    @months ||= begin
      out, cursor = [], @from
      while cursor <= @to
        out << cursor
        cursor = cursor.next_month
      end
      out
    end
  end

  # Returns: [{:name=>"Adult Briefs (XXL)", :data=>[0, 0, 0, ...]}]
  # :data holds one quantity per month in #months, oldest first.
  #
  # Each entry used to carry `visible: false`, which was a Highcharts rendering flag and the reason
  # all three trend pages opened with an empty chart. The chart plots one total per month now and
  # this is a table of figures again, with nothing in it about how to draw them.
  #
  # **The window is capped at now.** A distribution can be dated ahead of itself -- 10 of them here,
  # 82 line items -- and a *trend* is what happened, not what is booked. Mixing the two would make
  # the last column mean something different from every other one. The page says so rather than
  # dropping them silently; `#scheduled_beyond_today` is what it says it with.
  def series
    type_symbol = @type.tableize.to_sym # :distributions, :donations, :purchases
    records = @organization.send(type_symbol)
      .includes(items: :line_items)
      .where(issued_at: @from.beginning_of_day..window_end)

    slots = months.each_with_index.to_h { |month, index| [[month.year, month.month], index] }
    array_of_items = []

    records.each do |record|
      # Indexed off the window rather than off `Date.current.month`, which was modular arithmetic
      # that only landed correctly for a window of exactly twelve months ending this month.
      index = slots[[record.issued_at.year, record.issued_at.month]]
      next if index.nil?

      record.line_items.each do |line_item|
        next unless in_category?(line_item.item)

        name = line_item.item.name
        quantity = line_item.quantity
        next if quantity.zero?

        existing_item = array_of_items.find { |item| item[:name] == name }
        if existing_item
          existing_item[:data][index] += quantity
        else
          quantity_per_month = Array.new(months.size, 0)
          quantity_per_month[index] += quantity
          array_of_items << {name:, data: quantity_per_month}
        end
      end
    end

    array_of_items.sort_by { |item| item[:name] }
  end

  # How much is dated after today, so the page can say the trend does not include it. Zero for
  # donations and purchases, which are recorded after the fact.
  def scheduled_beyond_today
    return @scheduled_beyond_today if defined?(@scheduled_beyond_today)

    future = @organization.send(@type.tableize.to_sym).where("issued_at > ?", Time.zone.now)
    @scheduled_beyond_today = LineItem.where(itemizable: future).sum(:quantity)
  end

  # Whether the last bucket is still running. The current month is selectable -- "how are we doing
  # this month" is the question people ask most -- but it is never silently compared with a whole
  # one, so the view marks it.
  def last_month_in_progress?
    today = Time.zone.today
    months.last == today.beginning_of_month && today != today.end_of_month
  end

  # One total per month, every item added together. What the chart draws.
  def monthly_totals
    @monthly_totals ||= begin
      out = Array.new(months.size, 0)
      series.each { |item| item[:data].each_with_index { |value, i| out[i] += value.to_i } }
      out
    end
  end

  # The same window, shifted back by its own length: twelve months becomes the twelve before it,
  # six becomes the six before. Not "the same months last year" -- that is a different question and
  # answers it wrongly for any window that is not a whole year.
  def previous_totals
    @previous_totals ||= begin
      span = months.size
      shifted = self.class.new(@organization.id, @type,
        from: @from - span.months, to: @to.beginning_of_month - span.months + 1.month - 1.day,
        category_id: @category_id)
      shifted.monthly_totals
    end
  end

  def previous_window
    span = months.size
    [@from - span.months, (@from - 1.month).end_of_month]
  end

  # Per item *category*, oldest month first, largest first. The composition view: four bands from a
  # grouping the bank already maintains, rather than the arbitrary "top 8 and Other" cut that was
  # considered and rejected for setting a partial answer beside a complete one.
  def category_series
    @category_series ||= begin
      names = item_category_names
      buckets = Hash.new { |h, k| h[k] = Array.new(months.size, 0) }
      series.each do |item|
        bucket = names.fetch(item[:name], UNCATEGORISED)
        item[:data].each_with_index { |value, i| buckets[bucket][i] += value.to_i }
      end
      buckets.map { |name, data| {name: name, data: data} }.sort_by { |c| -c[:data].sum }
    end
  end

  UNCATEGORISED = "Uncategorised"

  private

  # The end of the window, never later than now: see #series.
  def window_end
    [@to.end_of_day, Time.zone.now].min
  end

  # Filtered in Ruby rather than in the query because the line items are already loaded by the
  # `includes` above -- adding a join to narrow them would cost a second pass over the same rows.
  def in_category?(item)
    return true if @category_id.nil?
    return item.item_category_id.nil? if @category_id == "none"

    item.item_category_id.to_s == @category_id.to_s
  end

  # item name => category name, for #category_series. Two queries rather than one per item, and
  # deliberately not `left_joins(:item_category)`: Item has both `item_category` and an
  # `item_categories` through-association, and joining by name raises
  # AmbiguousSourceReflectionForThroughAssociation.
  def item_category_names
    @item_category_names ||= begin
      categories = @organization.item_categories.pluck(:id, :name).to_h
      @organization.items.pluck(:name, :item_category_id)
        .to_h { |item_name, category_id| [item_name, categories[category_id] || UNCATEGORISED] }
    end
  end
end
