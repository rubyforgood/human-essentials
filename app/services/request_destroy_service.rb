class RequestDestroyService
  include ServiceObjectErrorsMixin

  def initialize(request_id:, reason: nil)
    @request_id = request_id
    @reason = reason
  end

  def call
    return self unless valid?

    request.discarded_at = Time.current
    request.discard_reason = reason
    request.status = :discarded
    request.save!

    RequestMailer.request_cancel_partner_notification(request_id: request.id).deliver_later

    self
  end

  private

  attr_reader :request_id, :reason

  def valid?
    if request.blank?
      errors.add(:base, 'request_id is invalid')
    elsif request.discarded_at.present?
      errors.add(:base, 'request already discarded')
    elsif request.partner.deactivated?
      errors.add(:base, 'partner is deactivated')
    end

    errors.none?
  end

  def request
    @request ||= Request.find_by(id: request_id)
  end
end
