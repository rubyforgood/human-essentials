module AuditUpsertService
  def self.call(audit, params)
    audit.params = params
    Audit.transaction do
      audit.save && AuditEvent.publish(audit)
    end
  end
end
