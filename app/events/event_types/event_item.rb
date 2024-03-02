module Types
  include Dry.Types()
end

module EventTypes
  class EventItem < Dry::Struct
    transform_keys(&:to_sym)
    attribute :item_id, Types::Integer
    attribute :quantity, Types::Integer
    attribute? :storage_location_id, Types::Integer
  end
end
