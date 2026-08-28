module Types
  include Dry.Types()
end

module EventTypes
  class EventItem < Dry::Struct
    transform_keys(&:to_sym)
    attribute :item_id, Types::Integer
    attribute :quantity, Types::Integer
    attribute :committed_quantity, Types::Integer.default(0)
    attribute? :storage_location_id, Types::Integer

    def physical_quantity
      quantity + committed_quantity
    end
  end
end
