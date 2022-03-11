require "icalendar"
require "icalendar/tzinfo"

module CalendarService
  # Prints out a calendar in ICS format for use e.g. in adding to Google Calendar.
  def self.calendar(organization_id)
    distributions = Organization.find(organization_id)
      .distributions
      .includes(:storage_location, :partner)

    cal = Icalendar::Calendar.new
    time_zones = Set.new
    distributions.each do |dist|
      tz_id = dist.storage_location.time_zone
      if time_zones.exclude?(tz_id)
        time_zones.add(tz_id)
        tz = TZInfo::Timezone.get(tz_id)
        ical_timezone = tz.ical_timezone(dist.issued_at)
        cal.add_timezone(ical_timezone)
      end

      cal.event do |e|
        e.dtstart = Icalendar::Values::DateTime.new(dist.issued_at, "tzid" => tz_id)
        e.dtend = Icalendar::Values::DateTime.new(dist.issued_at + 15.minutes, "tzid" => tz_id)
        e.summary = "Pickup from #{dist.partner.name}"
        e.location = dist.storage_location.address
        e.url = "https://www.human-essentials.com/diaper_bank/distributions/schedule"
      end
    end
    cal.publish
    cal.to_ical
  end
end
