module Types
  include Dry.Types()
end

module EventTypes
  class DonationPayload < InventoryPayload
    attribute :money_raised, Types::Integer.optional

    # @param json [Hash]
    # @return [Hash]
    def self.load_json(json)
      super.merge(money_raised: json[:money_raised])
    end

  end
end
