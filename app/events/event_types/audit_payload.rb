module Types
  include Dry.Types()
end

module EventTypes
  class AuditPayload < InventoryPayload
    attribute :storage_location_id, Types::Integer
  end
end
