# Custom time format key to display Distribution issued_at time where
# we're storing date & time but ignoring the timezone. So use this
# format to NOT show the time zone.
#
# Usage: @distribution.issued_at.to_fs(:distribution_date_time)
#
Time::DATE_FORMATS[:distribution_date_time] = "%B %-d %Y %-l:%M%P"
Time::DATE_FORMATS[:distribution_date] = "%B %-d %Y"
Time::DATE_FORMATS[:date_picker] = "%B %-d, %Y"

DateTime::DATE_FORMATS[:date_picker] = "%B %-d, %Y"
Date::DATE_FORMATS[:date_picker] = "%B %-d, %Y"

# What the date range trigger shows. US convention, and short: spelled out, a custom range read
# "June 19, 2026 to September 19, 2026" and needed 233px inside a 223px button, so it was
# truncated. The wire format above is unchanged -- the server still parses "%B %-d, %Y".
Time::DATE_FORMATS[:date_picker_short] = "%-m/%-d/%Y"
DateTime::DATE_FORMATS[:date_picker_short] = "%-m/%-d/%Y"
Date::DATE_FORMATS[:date_picker_short] = "%-m/%-d/%Y"
