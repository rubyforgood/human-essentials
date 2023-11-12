module AuditUpsertService
  def self.call(audit, params)
    audit.params = params
    audit.save && AuditEvent.publish(audit)
  end
end
