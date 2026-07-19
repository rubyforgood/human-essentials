class DeadlineService
  include ServiceObjectErrorsMixin

  def initialize(deadline_day:, today: nil)
    @deadline_day = deadline_day
    @today = today || Time.zone.today
  end

  def next_deadline
    return if @deadline_day.blank?

    next_date(@deadline_day)
  end

  def self.get_deadline_for_partner(partner)
    partner.partner_group&.deadline_day || partner.organization.deadline_day
  end

  private

  # Returns the first non-nil value for method receivers
  def next_date(day)
    date = ((@today.day >= day) ? @today.next_month : @today)
    date.change(day: day)
  end
end
