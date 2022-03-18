describe CalendarService do
  describe ".calendar" do
    it "should print the calendar correctly" do
      storage_location = create(:storage_location,
        time_zone: "America/New_York")
      time_zone = ActiveSupport::TimeZone["America/New_York"]
      travel_to time_zone.local(2021, 3, 18, 0, 0, 0) do
        partner1 = create(:partner, name: "Partner 1")
        partner2 = create(:partner, name: "Partner 2")
        create(:distribution, issued_at: time_zone.local(2022, 3, 17, 10, 0, 0),
                       partner: partner1,
                       storage_location: storage_location)
        create(:distribution, issued_at: time_zone.local(2022, 2, 17, 9, 0, 0),
                       partner: partner1,
                       storage_location: storage_location)
        create(:distribution, issued_at: time_zone.local(2019, 1, 1),
                       partner: partner2,
                       storage_location: storage_location)
        create(:distribution, issued_at: time_zone.local(2023, 3, 17),
                       partner: partner2,
                       storage_location: storage_location)
      end
      result = described_class.calendar(@organization.id)
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
        URL:https://humanessentials.app/diaper_bank/distributions/schedule
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;TZID=America/New_York:20220217T060000
        DTEND;TZID=America/New_York:20220217T061500
        LOCATION:1500 Remount Road\\, Front Royal\\, VA 22630
        SUMMARY:Pickup from Partner 1
        URL:https://humanessentials.app/diaper_bank/distributions/schedule
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;TZID=America/New_York:20230316T210000
        DTEND;TZID=America/New_York:20230316T211500
        LOCATION:1500 Remount Road\\, Front Royal\\, VA 22630
        SUMMARY:Pickup from Partner 2
        URL:https://humanessentials.app/diaper_bank/distributions/schedule
        END:VEVENT
        END:VCALENDAR
      ICAL
      # remove nondeterministic values and replace \n with \r\n
      result = result.gsub(/\r\nDTSTAMP:.*\r\n/, "\r\n").gsub(/\r\nUID:.*\r\n/, "\r\n")
      expect(result).to eq(expected.gsub("\n", "\r\n"))
    end
  end

  specify "#time_zones" do
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
      ["Newfoundland -03:30", "America/St_Johns"],
      ["International Date Line West -12:00", "Etc/GMT+12"],
      ["American Samoa -11:00", "Pacific/Pago_Pago"],
      ["Midway Island -11:00", "Pacific/Midway"],
      ["Tijuana -08:00", "America/Tijuana"],
      ["Mazatlan -07:00", "America/Mazatlan"],
      ["Chihuahua -07:00", "America/Chihuahua"],
      ["Monterrey -06:00", "America/Monterrey"],
      ["Mexico City -06:00", "America/Mexico_City"],
      ["Guadalajara -06:00", "America/Mexico_City"],
      ["Central America -06:00", "America/Guatemala"],
      ["Lima -05:00", "America/Lima"],
      ["Quito -05:00", "America/Lima"],
      ["Bogota -05:00", "America/Bogota"],
      ["Caracas -04:00", "America/Caracas"],
      ["Georgetown -04:00", "America/Guyana"],
      ["La Paz -04:00", "America/La_Paz"],
      ["Santiago -04:00", "America/Santiago"],
      ["Brasilia -03:00", "America/Sao_Paulo"],
      ["Buenos Aires -03:00", "America/Argentina/Buenos_Aires"],
      ["Greenland -03:00", "America/Godthab"],
      ["Montevideo -03:00", "America/Montevideo"],
      ["Mid-Atlantic -02:00", "Atlantic/South_Georgia"],
      ["Azores -01:00", "Atlantic/Azores"],
      ["Cape Verde Is. -01:00", "Atlantic/Cape_Verde"],
      ["Tokelau Is. +13:00", "Pacific/Fakaofo"],
      ["Nuku'alofa +13:00", "Pacific/Tongatapu"],
      ["Samoa +13:00", "Pacific/Apia"],
      ["Chatham Is. +12:45", "Pacific/Chatham"],
      ["Marshall Is. +12:00", "Pacific/Majuro"],
      ["Wellington +12:00", "Pacific/Auckland"],
      ["Fiji +12:00", "Pacific/Fiji"],
      ["Kamchatka +12:00", "Asia/Kamchatka"],
      ["Auckland +12:00", "Pacific/Auckland"],
      ["Solomon Is. +11:00", "Pacific/Guadalcanal"],
      ["New Caledonia +11:00", "Pacific/Noumea"],
      ["Magadan +11:00", "Asia/Magadan"],
      ["Srednekolymsk +11:00", "Asia/Srednekolymsk"],
      ["Vladivostok +10:00", "Asia/Vladivostok"],
      ["Sydney +10:00", "Australia/Sydney"],
      ["Port Moresby +10:00", "Pacific/Port_Moresby"],
      ["Melbourne +10:00", "Australia/Melbourne"],
      ["Hobart +10:00", "Australia/Hobart"],
      ["Canberra +10:00", "Australia/Melbourne"],
      ["Brisbane +10:00", "Australia/Brisbane"],
      ["Guam +10:00", "Pacific/Guam"],
      ["Adelaide +09:30", "Australia/Adelaide"],
      ["Darwin +09:30", "Australia/Darwin"],
      ["Seoul +09:00", "Asia/Seoul"],
      ["Sapporo +09:00", "Asia/Tokyo"],
      ["Tokyo +09:00", "Asia/Tokyo"],
      ["Yakutsk +09:00", "Asia/Yakutsk"],
      ["Osaka +09:00", "Asia/Tokyo"],
      ["Ulaanbaatar +08:00", "Asia/Ulaanbaatar"],
      ["Beijing +08:00", "Asia/Shanghai"],
      ["Chongqing +08:00", "Asia/Chongqing"],
      ["Hong Kong +08:00", "Asia/Hong_Kong"],
      ["Irkutsk +08:00", "Asia/Irkutsk"],
      ["Kuala Lumpur +08:00", "Asia/Kuala_Lumpur"],
      ["Singapore +08:00", "Asia/Singapore"],
      ["Taipei +08:00", "Asia/Taipei"],
      ["Perth +08:00", "Australia/Perth"],
      ["Krasnoyarsk +07:00", "Asia/Krasnoyarsk"],
      ["Jakarta +07:00", "Asia/Jakarta"],
      ["Hanoi +07:00", "Asia/Bangkok"],
      ["Bangkok +07:00", "Asia/Bangkok"],
      ["Novosibirsk +07:00", "Asia/Novosibirsk"],
      ["Rangoon +06:30", "Asia/Rangoon"],
      ["Almaty +06:00", "Asia/Almaty"],
      ["Urumqi +06:00", "Asia/Urumqi"],
      ["Dhaka +06:00", "Asia/Dhaka"],
      ["Astana +06:00", "Asia/Dhaka"],
      ["Kathmandu +05:45", "Asia/Kathmandu"],
      ["New Delhi +05:30", "Asia/Kolkata"],
      ["Chennai +05:30", "Asia/Kolkata"],
      ["Kolkata +05:30", "Asia/Kolkata"],
      ["Mumbai +05:30", "Asia/Kolkata"],
      ["Sri Jayawardenepura +05:30", "Asia/Colombo"],
      ["Tashkent +05:00", "Asia/Tashkent"],
      ["Ekaterinburg +05:00", "Asia/Yekaterinburg"],
      ["Islamabad +05:00", "Asia/Karachi"],
      ["Karachi +05:00", "Asia/Karachi"],
      ["Kabul +04:30", "Asia/Kabul"],
      ["Baku +04:00", "Asia/Baku"],
      ["Muscat +04:00", "Asia/Muscat"],
      ["Samara +04:00", "Europe/Samara"],
      ["Tbilisi +04:00", "Asia/Tbilisi"],
      ["Yerevan +04:00", "Asia/Yerevan"],
      ["Abu Dhabi +04:00", "Asia/Muscat"],
      ["Tehran +03:30", "Asia/Tehran"],
      ["Volgograd +03:00", "Europe/Volgograd"],
      ["St. Petersburg +03:00", "Europe/Moscow"],
      ["Riyadh +03:00", "Asia/Riyadh"],
      ["Moscow +03:00", "Europe/Moscow"],
      ["Minsk +03:00", "Europe/Minsk"],
      ["Kuwait +03:00", "Asia/Kuwait"],
      ["Istanbul +03:00", "Europe/Istanbul"],
      ["Baghdad +03:00", "Asia/Baghdad"],
      ["Nairobi +03:00", "Africa/Nairobi"],
      ["Jerusalem +02:00", "Asia/Jerusalem"],
      ["Sofia +02:00", "Europe/Sofia"],
      ["Kaliningrad +02:00", "Europe/Kaliningrad"],
      ["Riga +02:00", "Europe/Riga"],
      ["Pretoria +02:00", "Africa/Johannesburg"],
      ["Kyiv +02:00", "Europe/Kiev"],
      ["Vilnius +02:00", "Europe/Vilnius"],
      ["Athens +02:00", "Europe/Athens"],
      ["Bucharest +02:00", "Europe/Bucharest"],
      ["Cairo +02:00", "Africa/Cairo"],
      ["Harare +02:00", "Africa/Harare"],
      ["Helsinki +02:00", "Europe/Helsinki"],
      ["Tallinn +02:00", "Europe/Tallinn"],
      ["Skopje +01:00", "Europe/Skopje"],
      ["Stockholm +01:00", "Europe/Stockholm"],
      ["Vienna +01:00", "Europe/Vienna"],
      ["Warsaw +01:00", "Europe/Warsaw"],
      ["West Central Africa +01:00", "Africa/Algiers"],
      ["Zagreb +01:00", "Europe/Zagreb"],
      ["Zurich +01:00", "Europe/Zurich"],
      ["Amsterdam +01:00", "Europe/Amsterdam"],
      ["Belgrade +01:00", "Europe/Belgrade"],
      ["Berlin +01:00", "Europe/Berlin"],
      ["Bern +01:00", "Europe/Zurich"],
      ["Bratislava +01:00", "Europe/Bratislava"],
      ["Brussels +01:00", "Europe/Brussels"],
      ["Budapest +01:00", "Europe/Budapest"],
      ["Copenhagen +01:00", "Europe/Copenhagen"],
      ["Ljubljana +01:00", "Europe/Ljubljana"],
      ["Paris +01:00", "Europe/Paris"],
      ["Prague +01:00", "Europe/Prague"],
      ["Rome +01:00", "Europe/Rome"],
      ["Sarajevo +01:00", "Europe/Sarajevo"],
      ["Madrid +01:00", "Europe/Madrid"],
      ["UTC +00:00", "Etc/UTC"],
      ["Casablanca +00:00", "Africa/Casablanca"],
      ["Dublin +00:00", "Europe/Dublin"],
      ["Edinburgh +00:00", "Europe/London"],
      ["Lisbon +00:00", "Europe/Lisbon"],
      ["London +00:00", "Europe/London"],
      ["Monrovia +00:00", "Africa/Monrovia"]]

    expect(described_class.time_zones).to eq(expected)
  end
end
