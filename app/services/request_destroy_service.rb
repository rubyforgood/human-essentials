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

  # **Two layers, on purpose, and this branch was wrong about that.** The blank-reason check was
  # left out here on the grounds that the rule has one owner -- `Requests::Cancelation`, the form
  # object the controller validates first, which is the only one that can re-render the form with
  # what the user typed still in it -- and that adding it would refuse a cancellation in four
  # existing examples that do not pass a reason.
  #
  # main fixed the same bug (#5641) at this level and answered the objection: it threads a reason
  # through those four examples rather than leaving them reasonless. Both layers are kept. The form
  # object still owns the *user-facing* error, because it is the one that can put the message beside
  # the field; this is the backstop for every caller that is not that form, which the form object by
  # construction cannot cover.
  #
  # The first two are *states*, not validation of what the user typed, and neither is retryable:
  # nothing the person filling in the cancellation form can change will make a second attempt
  # succeed. The controller relies on that when it decides where to send them. The messages are
  # shown to users verbatim in a flash, so they read as sentence fragments that follow "could not
  # be cancelled --".
  def valid?
    if request.blank?
      errors.add(:base, 'we could not find it')
    elsif request.discarded_at.present?
      errors.add(:base, 'it has already been cancelled')
    elsif reason.blank?
      errors.add(:base, 'a cancellation reason is required')
    end

    errors.none?
  end

  def request
    @request ||= Request.find_by(id: request_id)
  end
end
