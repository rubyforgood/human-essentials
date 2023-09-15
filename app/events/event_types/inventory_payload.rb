module Types
  include Dry.Types()
end

module EventTypes
  class InventoryPayload < Dry::Struct
    transform_keys(&:to_sym)

    attribute :items, Types::Array.of(EventTypes::EventLineItem)
  end
end
