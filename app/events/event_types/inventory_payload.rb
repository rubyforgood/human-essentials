module Types
  include Dry.Types()
end

module EventTypes
  class InventoryPayload < Dry::Struct
    attribute :partner_id, Types::Integer
    attribute :items, Types::Array.of(Types.Instance(EventTypes::EventLineItem))
  end
end
