# Creates Error objects that are slightly more useful than plain ol' Standard Errors
module Errors
  # Use this Error for when a storage location does not have enough inventory on-hand to satisfy a request
  class InsufficientAllotment < StandardError
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
      super.to_s + (" " + insufficient_items.map do |i|
        "#{i[:quantity_requested]} #{i[:item_name]} requested, only #{i[:quantity_on_hand]} available." \
        "(Reduce by #{i[:quantity_requested].to_i - i[:quantity_on_hand].to_i})"
      end.join(""))
    end
  end

  class StorageLocationDoesNotMatch < StandardError
    def message
      "Storage location kit doesn't match"
    end
  end

  class KitAllocationNotExists < StandardError
    def message
      "KitAllocation not found for given kit"
    end
  end

  class InventoryAlreadyHasItems < StandardError
    def message
      "Could not complete action: inventory already has items stored"
    end
  end
end
