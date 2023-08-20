class ApplicationEvent < RailsEventStore::Event
  # @param payload [Dry::Struct]
  # @return [Class<ApplicationEvent>]
  def self.from_payload(payload)
    self.new(event_id: SecureRandom.uuid, metadata: {}, data: payload.attributes)
  end
end
