# Custom time format key to display Distribution issued_at time where
# we're storing date & time but ignoring the timezone. So use this
# format to NOT show the time zone.
#
# Usage: @distribution.issued_at.to_s(:distribution_date_time)
#
Time::DATE_FORMATS[:distribution_date_time] = "%B %-d %Y %-l:%M%P"
Time::DATE_FORMATS[:distribution_date] = "%B %-d %Y"
