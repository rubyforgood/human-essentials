require "icalendar"
require "icalendar/tzinfo"

module CalendarService
  # Prints out a calendar in ICS format for use e.g. in adding to Google Calendar.
  # @param organization_id [Integer]
  # @return [String]
  def self.calendar(organization_id)
    distributions = Organization.find(organization_id)
      .distributions
      .includes(:storage_location, :partner)
      .where("issued_at > ?", 1.year.ago)

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
        e.url = "https://humanessentials.app/diaper_bank/distributions/schedule"
      end
    end
    cal.publish
    cal.to_ical
  end

  # @return [Hash<String, String>]
  def self.time_zones
    return @zones if @zones

    initial_zones = %w[
      Pacific/Honolulu
      America/Juneau
      America/Los_Angeles
      America/Phoenix
      America/Denver
      America/Regina
      America/Chicago
      America/New_York
      America/Indiana/Indianapolis
      America/Puerto_Rico
      America/Halifax
      America/St_Johns
    ]

    zones = ActiveSupport::TimeZone.all.sort_by(&:formatted_offset).reverse
    initial_zones.reverse_each do |zone_name|
      index = zones.index { |zone| zone.tzinfo.name == zone_name }
      next unless index
      zones = [zones.delete_at(index)] + zones
    end

    @zones = zones.map { |z| ["#{z.name} #{z.formatted_offset}", z.tzinfo.name] }
    @zones
  end
end
