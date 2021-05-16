class RequestDestroyService
  include ServiceObjectErrorsMixin

  def initialize(request_id:)
    @request_id = request_id
  end

  def call
    return self unless valid?

    request.discard!
    RequestMailer.request_cancel_partner_notification(request_id: request.id).deliver_later

    self
  end

  private

  attr_reader :request_id

  def valid?
    if request.blank?
      errors.add(:base, 'request_id is invalid')
    elsif request.discarded_at.present?
      errors.add(:base, 'request already discarded')
    end

    errors.none?
  end

  def request
    @request ||= Request.find_by(id: request_id)
  end
end
