module Types
  include Dry.Types()
end

module EventTypes
  class DistributionPayload < InventoryPayload
    attribute :reserves_inventory, Types::Bool.default(false)
  end
end
