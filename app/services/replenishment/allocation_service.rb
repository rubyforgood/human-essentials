# frozen_string_literal: true

module Replenishment
  # Looks at every open partner request for one item and, if the bank can't
  # fill them all, proposes how to split what is on hand.
  class AllocationService
    OPEN_STATUSES = %w[pending started].freeze

    Line = Data.define(:request, :partner, :quantity)

    def initialize(organization, item, reserve: 0)
      @organization = organization
      @item = item
      @reserve = reserve.to_i
    end

    def on_hand
      @on_hand ||= View::Inventory.new(@organization.id).quantity_for(item_id: @item.id).to_i
    end

    def supply
      [on_hand - @reserve, 0].max
    end

    def lines
      @lines ||= @organization.requests.kept
        .where(status: OPEN_STATUSES)
        .includes(:partner)
        .order(:created_at)
        .filter_map do |request|
          qty = Array(request.request_items)
            .select { |line| line["item_id"].to_i == @item.id }
            .sum { |line| line["quantity"].to_i }
          Line.new(request:, partner: request.partner, quantity: qty) if qty.positive?
        end
    end

    def requested
      lines.sum(&:quantity)
    end

    def shortfall?
      requested > supply
    end

    # => { proportional: Plan, max_min: Plan }, keyed by request id
    def plans
      requests = lines.to_h { |line| [line.request.id, line.quantity] }
      FairAllocator.new(supply: supply, requests: requests).compare
    end
  end
end
