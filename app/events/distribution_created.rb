module Types
  include Dry.Types()
end

class DistributionCreated < Dry::Struct
  attribute :organization_id, Types::Integer
  attribute :storage_location_id, Types::Integer
  attribute :partner_id, Types::Integer
  attribute :items, Types::Array.of(Types.Instance(EventTypes::EventLineItem))

  class DistributionCreatedEvent < RailsEventStore::Event; end

  # @param distribution [Distribution]
  # @return [DistributionCreatedEvent]
  def self.from_distribution(distribution)
    self.new(
      organization_id: distribution.organization_id,
      storage_location_id: distribution.storage_location_id,
      partner_id: distribution.partner_id,
      items: distribution.line_items.map { |i| EventTypes::EventLineItem.from_line_item(i) }
    ).to_res_event
  end

  def to_res_event
    EventTransform.to_res_event(DistributionCreatedEvent, self)
  end

end
