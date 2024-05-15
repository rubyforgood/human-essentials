RSpec.describe CalendarService do
  let(:organization) { create(:organization) }

  describe ".calendar" do
    it "should print the calendar correctly" do
      storage_location = create(:storage_location,
        time_zone: "America/New_York", organization: organization)
      time_zone = ActiveSupport::TimeZone["America/New_York"]
      travel_to time_zone.local(2021, 3, 18, 0, 0, 0) do
        partner1 = create(:partner, name: "Partner 1", organization: organization)
        partner2 = create(:partner, name: "Partner 2", organization: organization)
        create(:distribution, issued_at: time_zone.local(2022, 3, 17, 10, 0, 0),
          partner: partner1, storage_location: storage_location)
        create(:distribution, issued_at: time_zone.local(2022, 2, 17, 9, 0, 0),
          partner: partner1, storage_location: storage_location)
        create(:distribution, issued_at: time_zone.local(2019, 1, 1),
          partner: partner2, storage_location: storage_location)
        create(:distribution, issued_at: time_zone.local(2023, 3, 17),
          partner: partner2, storage_location: storage_location)
        result = described_class.calendar(organization.id)
        expected = <<~ICAL
          BEGIN:VCALENDAR
          VERSION:2.0
          PRODID:icalendar-ruby
          CALSCALE:GREGORIAN
          METHOD:PUBLISH
          BEGIN:VTIMEZONE
          TZID:America/New_York
          BEGIN:DAYLIGHT
          DTSTART:20220313T030000
          TZOFFSETFROM:-0500
          TZOFFSETTO:-0400
          RRULE:FREQ=YEARLY;BYDAY=2SU;BYMONTH=3
          TZNAME:EDT
          END:DAYLIGHT
          BEGIN:STANDARD
          DTSTART:20221106T010000
          TZOFFSETFROM:-0400
          TZOFFSETTO:-0500
          RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=11
          TZNAME:EST
          END:STANDARD
          END:VTIMEZONE
          BEGIN:VEVENT
          DTSTART;TZID=America/New_York:20220317T070000
          DTEND;TZID=America/New_York:20220317T071500
          LOCATION:1500 Remount Road\\, Front Royal\\, VA 22630
          SUMMARY:Pickup from Partner 1
          URL;VALUE=URI:https://humanessentials.app/diaper_bank/distributions/schedul
           e
          END:VEVENT
          BEGIN:VEVENT
          DTSTART;TZID=America/New_York:20220217T060000
          DTEND;TZID=America/New_York:20220217T061500
          LOCATION:1500 Remount Road\\, Front Royal\\, VA 22630
          SUMMARY:Pickup from Partner 1
          URL;VALUE=URI:https://humanessentials.app/diaper_bank/distributions/schedul
           e
          END:VEVENT
          BEGIN:VEVENT
          DTSTART;TZID=America/New_York:20230316T210000
          DTEND;TZID=America/New_York:20230316T211500
          LOCATION:1500 Remount Road\\, Front Royal\\, VA 22630
          SUMMARY:Pickup from Partner 2
          URL;VALUE=URI:https://humanessentials.app/diaper_bank/distributions/schedul
           e
          END:VEVENT
          END:VCALENDAR
        ICAL
        # remove nondeterministic values and replace \n with \r\n
        result = result.gsub(/\r\nDTSTAMP:.*\r\n/, "\r\n").gsub(/\r\nUID:.*\r\n/, "\r\n")
        expect(result).to eq(expected.gsub("\n", "\r\n"))
      end
    end
  end

  specify "#time_zones" do
    # can't do a full comparison because order matters in the first part but not in the
    # rest of it, and the rest of it can change the order since there are multiple
    # time zones with the same offset.
    expected = [["Hawaii -10:00", "Pacific/Honolulu"],
      ["Alaska -09:00", "America/Juneau"],
      ["Pacific Time (US & Canada) -08:00", "America/Los_Angeles"],
      ["Arizona -07:00", "America/Phoenix"],
      ["Mountain Time (US & Canada) -07:00", "America/Denver"],
      ["Saskatchewan -06:00", "America/Regina"],
      ["Central Time (US & Canada) -06:00", "America/Chicago"],
      ["Eastern Time (US & Canada) -05:00", "America/New_York"],
      ["Indiana (East) -05:00", "America/Indiana/Indianapolis"],
      ["Puerto Rico -04:00", "America/Puerto_Rico"],
      ["Atlantic Time (Canada) -04:00", "America/Halifax"],
      ["Newfoundland -03:30", "America/St_Johns"]]

    result = described_class.time_zones
    expect(result.size).to eq(151)
    expect(result[0..11]).to eq(expected)
  end
end
