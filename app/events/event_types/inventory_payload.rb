module Types
  include Dry.Types()
end

module EventTypes
  class InventoryPayload < Dry::Struct
    transform_keys(&:to_sym)
    attribute :items, Types::Array.of(Types.Instance(EventTypes::EventLineItem))

    # @param json [Hash]
    # @return [Hash]
    def self.load_json(json)
      {
        items: json[:items]&.map { |i| EventTypes::EventLineItem.new(i) } || []
      }
    end

  end
end
