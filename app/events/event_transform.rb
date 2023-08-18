module EventTransform
  # @param klass [Class<RailsEventStore::Event>]
  # @param struct [Dry::Struct]
  # @return [RailsEventStore::Event]
  def self.to_res_event(klass, struct)
    klass.new(event_id: SecureRandom.uuid, metadata: {}, data: struct.attributes)
  end
end
