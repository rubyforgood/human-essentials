# frozen_string_literal: true

module Replenishment
  # Stock and recent demand for one item at each storage location, so staff
  # can see "I'm running out at this warehouse" even when the bank-wide total
  # looks fine.
  #
  # Demand here is a plain recent average (units distributed from that
  # location per month over the last few complete months). It is deliberately
  # simpler than the bank-wide forecast: per-location histories are short and
  # noisy, and the question at this level is only "how many days will this
  # shelf last?"
  class LocationBreakdown
    DAYS_PER_MONTH = 30.4

    Row = Data.define(:storage_location, :on_hand, :monthly_demand) do
      def days_of_supply
        return nil unless monthly_demand.positive?

        (on_hand / (monthly_demand / DAYS_PER_MONTH)).floor
      end
    end

    def initialize(organization, item, months: 3, today: Date.current)
      @organization = organization
      @item = item
      @months = months
      @last_month = today.beginning_of_month.prev_month
      @first_month = @last_month.months_ago(months - 1)
    end

    # Locations that hold the item or shipped it recently, fewest days of
    # supply first; locations with no recent demand go last.
    def rows
      @rows ||= begin
        inventory = View::Inventory.new(@organization.id)
        shipped = shipped_by_location
        @organization.storage_locations.active.alphabetized.filter_map do |location|
          on_hand = inventory.quantity_for(storage_location: location.id, item_id: @item.id).to_i
          monthly = shipped.fetch(location.id, 0) / @months.to_f
          next if on_hand.zero? && monthly.zero?

          Row.new(storage_location: location, on_hand:, monthly_demand: monthly.round(1))
        end.sort_by { |row| [row.days_of_supply || Float::INFINITY, row.storage_location.name] }
      end
    end

    private

    def shipped_by_location
      LineItem
        .joins("INNER JOIN distributions ON distributions.id = line_items.itemizable_id AND line_items.itemizable_type = 'Distribution'")
        .where(item_id: @item.id)
        .where(distributions: {organization_id: @organization.id,
                               issued_at: @first_month.beginning_of_day..@last_month.end_of_month.end_of_day})
        .group("distributions.storage_location_id")
        .sum(:quantity)
    end
  end
end
