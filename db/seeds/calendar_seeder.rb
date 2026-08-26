# Distributions positioned for exercising the pick ups and deliveries calendar.
#
# Deliberately not random. `db/seeds.rb` already scatters twenty distributions across a couple of
# years, which leaves the calendar page thin in the places you need to look at it: the month you
# land on is sparse, the next month is often empty, no day holds enough to overflow, and nothing
# falls on today. Each group below exists to make one thing on that page visible.
#
# Everything goes through DistributionCreateService rather than Distribution.create. Inventory here
# is event-sourced -- see CLAUDE.md -- so a raw insert leaves InventoryAggregate disagreeing with
# the rows, and the disagreement only surfaces later as a validation failure somewhere unrelated.
class CalendarSeeder
  MARKER = "Calendar test data".freeze

  # A distribution needs stock to draw down; below this there is no headroom and the service fails.
  MINIMUM_ON_HAND = 40

  def initialize(organization, today: Time.zone.today)
    @organization = organization
    @today = today
    @partners = organization.partners.to_a
    @by_month = Hash.new(0)
    @failures = []
  end

  def call
    raise "#{@organization.name} has no partners to distribute to" if @partners.empty?

    plan.each_with_index { |entry, index| create(entry, index) }

    {by_month: @by_month, total: @by_month.values.sum, failures: @failures}
  end

  private

  # [date, hour, complete?]
  def plan
    entries = []

    # Something on today, so the tinted cell and its brand-700 date have an event beside them.
    entries << [@today, 9, false]

    # One crowded day, to force the "+N more" overflow `dayMaxEvents` draws. Six clears it on any
    # reasonable row height; three did not.
    6.times { |i| entries << [@today + 3, 8 + i, false] }

    # The rest of this month, so the landing view is not two events in a corner.
    [1, 2, 5].each { |offset| entries << [@today + offset, [10, 13, 15].sample, false] }

    # Last month, and completed -- both because Prev should land on something, and so the data has
    # more than one state in it. A distribution dated before today that still says "scheduled" is
    # a small lie the seeds tell everywhere else.
    previous = @today.prev_month.beginning_of_month
    [4, 11, 19, 25].each { |offset| entries << [previous + offset, [9, 14].sample, true] }

    # Next month and the one after, so Next and Next-again both land on populated months.
    following = @today.next_month.beginning_of_month
    [2, 4, 9, 14, 18, 23, 28].each { |offset| entries << [following + offset, [9, 11, 14, 16].sample, false] }

    after = @today.next_month.next_month.beginning_of_month
    [6, 15, 21].each { |offset| entries << [after + offset, [10, 14].sample, false] }

    entries
  end

  def create(entry, index)
    date, hour, complete = entry
    distribution = build(date, hour, index)
    return @failures << "#{date}: not enough stock in any location" if distribution.nil?

    result = DistributionCreateService.new(distribution).call
    if result.success?
      @by_month[date.strftime("%Y-%m")] += 1
      distribution.update!(state: :complete) if complete
    else
      @failures << "#{date}: #{result.error}"
    end
  end

  def build(date, hour, index)
    # Re-read per distribution: each one it creates changes what is left.
    inventory = InventoryAggregate.inventory_for(@organization.id)
    location, stock = stocked_location(inventory)
    return nil if location.nil?

    method = Distribution.delivery_methods.keys[index % Distribution.delivery_methods.size]
    distribution = Distribution.new(
      storage_location: location,
      partner: @partners[index % @partners.size],
      organization: @organization,
      issued_at: Time.zone.local(date.year, date.month, date.day, hour, 0),
      created_at: 3.days.ago(date.to_time),
      delivery_method: method,
      shipping_cost: (method == "shipped") ? rand(20.0..90.0).round(2).to_s : nil,
      comment: MARKER
    )
    stock.sample(2).each do |item|
      distribution.line_items.push(LineItem.new(quantity: rand(2..6), item_id: item.item_id))
    end
    distribution
  end

  def stocked_location(inventory)
    @organization.storage_locations.active.shuffle.each do |location|
      held = inventory.storage_locations[location.id]
      next if held.nil?

      stock = held.items.values.select { |item| item.quantity > MINIMUM_ON_HAND }
      return [location, stock] if stock.size >= 2
    end
    [nil, nil]
  end
end
