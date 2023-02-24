class DeadlineService
  include ServiceObjectErrorsMixin

  def initialize(partner:)
    @partner = partner
    @today = Time.zone.today
  end

  def next_deadline
    day = @partner.partner_group&.deadline_day ||
      @partner.organization.deadline_day

    return if day.blank?

    next_date(day)
  end

  private

  # Returns the first non-nil value for method receivers
  def next_date(day)
    date = ((@today.day >= day) ? @today.next_month : @today)
    date.change(day: day)
  end
end
