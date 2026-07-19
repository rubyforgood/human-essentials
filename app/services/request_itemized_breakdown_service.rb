class RequestItemizedBreakdownService
  class << self
    def call(organization:, request_ids:, format: :hash)
      data = fetch(organization: organization, request_ids: request_ids)
      (format == :csv) ? convert_to_csv(data) : data
    end

    def fetch(organization:, request_ids:)
      inventory = View::Inventory.new(organization.id)
      current_onhand = current_onhand_quantities(inventory)
      current_min_onhand = current_onhand_minimums(inventory)
      items_requested = fetch_items_requested(organization: organization, request_ids: request_ids)

      items_requested.each do |item|
        id = item[:item_id]

        on_hand = current_onhand[id]
        minimum = current_min_onhand[id]
        below_onhand_minimum = on_hand && minimum && on_hand < minimum

        item.merge!(
          on_hand: on_hand,
          onhand_minimum: minimum,
          below_onhand_minimum: below_onhand_minimum
        )
      end

      items_requested.sort_by { |item| [item[:name], item[:unit].to_s] }
    end

    def csv(organization:, request_ids:)
      convert_to_csv(fetch(organization: organization, request_ids: request_ids))
    end

    private

    def current_onhand_quantities(inventory)
      inventory.all_items.group_by(&:item_id).to_h { |item_id, rows| [item_id, rows.sum { |r| r.quantity.to_i }] }
    end

    def current_onhand_minimums(inventory)
      inventory.all_items.group_by(&:item_id).to_h { |item_id, rows| [item_id, rows.map(&:on_hand_minimum_quantity).compact.max] }
    end

    def fetch_items_requested(organization:, request_ids:)
      Partners::ItemRequest
        .includes(:item)
        .where(partner_request_id: request_ids)
        .group_by { |ir| [ir.item_id, ir.request_unit] }
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
  end
end
