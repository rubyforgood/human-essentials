# The window for a chart that buckets by month.
#
# A sibling of DateRangeHelper rather than a reuse of it, and the difference is the whole point: the
# date filter is **day**-granular, and a day-granular range over a monthly chart produces partial
# months at both ends -- short end columns with nothing on the chart saying why, which reads as a
# fall rather than as an artefact of the range. Xero and QuickBooks put month pickers on monthly
# reports for exactly this reason; Grafana and Metabase instead make granularity a control of its
# own. See "A period chart takes a period range" in design.md.
#
# Wire format is one parameter, `filters[months]`, holding two ISO months: "2025-09 - 2026-08".
# Shorter than the date filter's `"June 19, 2026 - September 19, 2026"` because there is nothing to
# disambiguate -- an ISO month cannot be read in two orders.
module MonthRangeHelper
  MONTH_RANGE_SEPARATOR = " - "
  DEFAULT_MONTH_SPAN = 12

  # Whole months only, and never later than the current one.
  #
  # **The current month is offered**, not withheld until it completes. "How are we doing this month"
  # is the question people ask most of a trend, and a control that cannot answer it sends them to
  # count rows instead. It is never silently compared with a whole month either: the view marks the
  # last column when it is still running -- which is what Google Analytics does with the incomplete
  # period, and Stripe with the current one.
  def month_range_presets
    this_month = Time.zone.today.beginning_of_month
    {
      "Last 6 months" => [this_month - 5.months, this_month],
      "Last 12 months" => [this_month - 11.months, this_month],
      "Last 24 months" => [this_month - 23.months, this_month],
      "This year to date" => [this_month.beginning_of_year, this_month],
      "Last calendar year" => [(this_month - 1.year).beginning_of_year, (this_month - 1.year).end_of_year.beginning_of_month]
    }
  end

  def default_month_range
    this_month = Time.zone.today.beginning_of_month
    [this_month - (DEFAULT_MONTH_SPAN - 1).months, this_month]
  end

  # [from, to] as the first of each month. Anything unparseable falls back to the default rather
  # than raising: a hand-edited query string should not take the page down.
  def selected_month_range
    raw = params.dig(:filters, :months).to_s
    from_s, to_s = raw.split(MONTH_RANGE_SEPARATOR)
    from = Date.strptime(from_s.to_s.strip, "%Y-%m")
    to = Date.strptime(to_s.to_s.strip, "%Y-%m")
    from, to = to, from if from > to
    # Never past the current month: the chart has nothing to draw beyond it, and offering it would
    # add empty columns that look like a collapse in activity.
    ceiling = Time.zone.today.beginning_of_month
    [[from, ceiling].min, [to, ceiling].min]
  rescue Date::Error, TypeError
    default_month_range
  end

  def selected_month_preset
    month_range_presets.find { |_name, range| range == selected_month_range }&.first
  end

  # "Sep 2025 – Aug 2026", or the preset's own name when one matches.
  def month_range_summary
    selected_month_preset || begin
      from, to = selected_month_range
      "#{from.strftime("%b %Y")} – #{to.strftime("%b %Y")}"
    end
  end

  def month_range_param(from, to) = "#{from.strftime("%Y-%m")}#{MONTH_RANGE_SEPARATOR}#{to.strftime("%Y-%m")}"

  # Whether the range is the one the page would have shown anyway, so the filter chip can stay away
  # until somebody has actually chosen something.
  def month_range_default? = selected_month_range == default_month_range
end
