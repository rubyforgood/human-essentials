module Errors
  class InsufficientAllotment < StandardError
    # TODO: This should be removed once other models no longer depend on it; it should be encapsulated and accessed through an interface
    attr_accessor :insufficient_items

    def initialize(message, insufficient_items = [])
      super(message)
      @insufficient_items = insufficient_items
    end

    ###
    # add_insufficiency
    #   Adds a note of insufficiency, to keep the list encapsulated
    ###
    def add_insufficiency(item, quantity_on_hand, quantity_requested)
      insufficient_items << {
        item_id: item.id,
        item: item.name,
        quantity_on_hand: quantity_on_hand.to_i,
        quantity_requested: quantity_requested.to_i
      }
    end

    ###
    # satisfied?
    #   Informs the model that we're OK here, so that we don't have to expose the field
    ###
    def satisfied?
      insufficient_items.empty?
    end

    ###
    # message
    #   overrides the default behavior by showing the message and then the items
    #   that are insufficient.
    ###
    def message
      super.to_s + ("<ul><li>" + insufficient_items.map do |i|
        "#{i[:quantity_requested]} #{i[:item]} requested, only #{i[:quantity_on_hand]} available." \
        "(Reduce by #{i[:quantity_requested].to_i - i[:quantity_on_hand].to_i})"
      end.join("</li><li>") + "</li></ul>")
    end
  end
end
