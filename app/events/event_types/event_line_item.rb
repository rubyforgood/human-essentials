module Types
  include Dry.Types()
end

module EventTypes
  class EventLineItem < Dry::Struct
    attribute :quantity, Types::Integer
    attribute :item_id, Types::Integer
    attribute :item_value_in_cents, Types::Integer

    # @param line_item [LineItem]
    # @return [EventLineItem]
    def self.from_line_item(line_item)
      self.new(
        quantity: line_item.quantity,
        item_id: line_item.item_id,
        item_value_in_cents: line_item.item.value_in_cents
      )
    end

  end
end
