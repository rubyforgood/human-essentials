module Types
  include Dry.Types()
end

class DistributionCreated < ApplicationEvent

  class Payload < Dry::Struct
    attribute :organization_id, Types::Integer
    attribute :storage_location_id, Types::Integer
    attribute :partner_id, Types::Integer
    attribute :items, Types::Array.of(Types.Instance(EventTypes::EventLineItem))
  end

  # @param distribution [Distribution]
  # @return [DistributionCreatedEvent]
  def self.publish(distribution)
    event = self.from_payload(Payload.new(
      organization_id: distribution.organization_id,
      storage_location_id: distribution.storage_location_id,
      partner_id: distribution.partner_id,
      items: distribution.line_items.map { |i| EventTypes::EventLineItem.from_line_item(i) }
    ))
    Rails.configuration.event_store.publish(event, stream_name: "org-#{distribution.organization_id}")
  end
end
