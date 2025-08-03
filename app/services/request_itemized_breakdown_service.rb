class RequestItemizedBreakdownService
  #
  # Initializes the RequestItemizedBreakdownService whose
  # purpose is to construct an itemized breakdown of requested items
  #
  # @param organization [Organization]
  # @param request_ids [Array<Integer>]
  # @return [RequestItemizedBreakdownService]
  def initialize(organization:, request_ids:)
    @organization = organization
    @request_ids = request_ids
  end

  #
  # Returns a hash containing the itemized breakdown of
  # requested items.
  #
  # @return [Array]
  def fetch
    inventory = View::Inventory.new(@organization.id)
    current_onhand = current_onhand_quantities(inventory)
    current_min_onhand = current_onhand_minimums(inventory)
    items_requested = fetch_items_requested

    items_requested.map! do |item|
      item_id = item[:item_id]

      on_hand = current_onhand[item_id]
      minimum = current_min_onhand[item_id]

      below_onhand_minimum = on_hand && minimum && on_hand < minimum

      item.merge(
        on_hand: on_hand,
        onhand_minimum: minimum,
        below_onhand_minimum: below_onhand_minimum
      )
    end

    items_requested.sort_by { |item| [item[:name], item[:unit].to_s] }
  end

  #
  # Returns a CSV string representation of the itemized breakdown of
  # what was requested
  #
  # @return [String]
  def fetch_csv
    convert_to_csv(fetch)
  end

  private

  attr_reader :organization, :request_ids

  def current_onhand_quantities(inventory)
    inventory.all_items.group_by(&:id).to_h do |id, items|
      [id, items.sum(&:quantity)]
    end
  end

  def current_onhand_minimums(inventory)
    inventory.all_items.group_by(&:id).to_h do |id, items|
      [id, items.map(&:on_hand_minimum_quantity).compact.max]
    end
  end

  def fetch_items_requested
    Request
      .includes(:partner, :organization, :item_requests)
      .where(id: @request_ids)
      .flat_map do |request|
        request.request_items.map do |json_item|
          RequestItem.from_json(json_item, request)
        end
      end
      .group_by { |ri| [ri.item.id, ri.unit] }
      .map do |(item_id, unit), grouped|
        item = grouped.first.item
        {
          item_id: item.id,
          name: item.name,
          unit: unit,
          quantity: grouped.sum { |ri| ri.quantity.to_i }
        }
      end
  end

  def convert_to_csv(items_requested_data)
    CSV.generate do |csv|
      csv << ["Item", "Total Requested", "Total On Hand"]
      items_requested_data.each do |item|
        csv << [item[:name], item[:quantity], item[:on_hand]]
      end
    end
  end

  def inventory
    @inventory ||= View::Inventory.new(@organization.id)
  end
end
