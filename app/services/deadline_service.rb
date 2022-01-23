class DeadlineService
  include ServiceObjectErrorsMixin

  RECEIVERS = %i[partner_group organization].freeze

  def initialize(partner:)
    @partner = partner
    @today = Time.zone.today
  end

  def next_deadline
    day = from_receivers(:deadline_day)

    return if day.blank?

    next_date(day)
  end

  private

  # Returns the first non-nil value for method receivers
  def from_receivers(method)
    RECEIVERS.each do
      val = @partner.__send__(_1).send(method)
      return val if val
    end
  end

  def next_date(day)
    date = (@today.day >= day ? @today.next_month : @today)
    date.change(day: day)
  end
end
