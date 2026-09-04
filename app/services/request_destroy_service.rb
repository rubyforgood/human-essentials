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
    request.status = :cancelled
    request.save!

    unless request.partner.deactivated?
      RequestMailer.request_cancel_partner_notification(request_id: request.id).deliver_later
    end

    self
  end

  private

  attr_reader :request_id, :reason

  # **States only.** Whether the reason is present is input validation and belongs to
  # `Requests::Cancelation`, the form object the controller validates first -- one owner for the
  # rule, and it is the owner that can re-render the form with what the user typed still in it.
  # Duplicating it here would also have made this service refuse a cancellation in four existing
  # examples that legitimately do not care about the reason.
  #
  # Both of these are *states*, not validation of what the user typed, and neither is retryable:
  # nothing the person filling in the cancellation form can change will make a second attempt
  # succeed. The controller relies on that when it decides where to send them. The messages are
  # shown to users verbatim in a flash, so they read as sentence fragments that follow "could not
  # be cancelled --".
  def valid?
    if request.blank?
      errors.add(:base, 'we could not find it')
    elsif request.discarded_at.present?
      errors.add(:base, 'it has already been cancelled')
    end

    errors.none?
  end

  def request
    @request ||= Request.find_by(id: request_id)
  end
end
