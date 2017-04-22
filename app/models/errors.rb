module Errors
  class InsufficientAllotment < StandardError
    attr_accessor :insufficient_items

    def initialize(message, insufficient_items=[])
      super(message)
      @insufficient_items = insufficient_items
    end

    def add_insufficiency(item, quantity_on_hand, quantity_requested)
      insufficient_items << {
        item: item.to_s,
        quantity_on_hand: quantity_on_hand.to_i,
        quantity_requested: quantity_requested.to_i
      }
    end
  end
end

