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

  # --- What the page is looking at -----------------------------------------
  #
  # One control, not two. A single-select in the filter bar *and* checkboxes in the table were two
  # answers to "what am I looking at", and ticking a row cost a full page load -- measured at
  # **1,702px of scroll lost** on the 21st of 47 rows. `shared/compare_picker` replaces both.
  #
  # The wire format is one repeated parameter, `filters[compare_with][]`, holding entries of the
  # form `cat:12` or `item:Kids (Size 2)`. Two kinds in one list because they answer the same
  # question -- what should this page be about -- and a reader thinking "how are nappies doing"
  # should not have to know whether nappies is a category or an item.
  COMPARE_CAP = 4

  # [[kind, value], ...] with the cap applied. Order is the reader's, because it decides which line
  # gets the solid dash.
  def selected_comparisons
    Array(params.dig(:filters, :compare_with)).map(&:to_s).compact_blank.uniq
      .filter_map { |entry|
        kind, value = entry.split(":", 2)
        [kind, value] if %w[cat item].include?(kind) && value.present?
      }.first(COMPARE_CAP)
  end

  def compare_cap_reached? = selected_comparisons.size >= COMPARE_CAP

  # Solid first, so a single choice is an ordinary line.
  PLOT_DASHES = ["Solid", "Dash", "Dot", "DashDot"].freeze
  # Each is >= 3:1 against the white plot, which is what WCAG 1.4.11 asks of a line. They are *not*
  # relied on to tell two lines apart -- the dash pattern and the legend word do that, because of
  # 28 pairs from an eight-colour candidate set, none clears 3:1 under normal vision and three kinds
  # of colour blindness.
  PLOT_COLOURS = ["#4F46E5", "#B4232E", "#0F766E", "#B45309"].freeze

  # --- Comparing with the window before this one ----------------------------

  # Whether to draw the window before this one behind the current figures.
  def compare_previous? = params.dig(:filters, :compare).to_s == "1"

  # "up 31%", "down 4%", "unchanged", or nil when there is nothing to compare against. Words, not an
  # arrow: design.md does not allow a signal that only a sighted reader gets, and a percentage with
  # no direction in it reads as a quantity rather than a change.
  def trend_change_phrase(current, previous)
    return nil if previous.to_i.zero?

    delta = current - previous
    return "unchanged from the previous period" if delta.zero?

    percent = (delta.abs * 100.0 / previous).round
    "#{delta.positive? ? "up" : "down"} #{percent}% on the previous period"
  end
  # --- The chip row under the bar -------------------------------------------
  #
  # Links, not form controls. The chips sit outside the filter bar's form -- they have to, because
  # four of them are 659px and the bar's cell is 256 -- so a link is the thing that works there with
  # no JavaScript and no second controller. Each one is this page minus that selection.

  def compare_chip_entries(categories, series)
    selected_comparisons.each_with_index.filter_map { |(kind, value), i|
      label = (kind == "cat") ? categories.find { |c| c.id.to_s == value }&.name : value
      next if label.nil?
      next if kind == "item" && series.none? { |item| item[:name] == value }

      {label: label, entry: "#{kind}:#{value}",
       colour: PLOT_COLOURS[i], dash: PLOT_DASHES[i]}
    }
  end

  def compare_without(entry)
    kept = selected_comparisons.map { |kind, value| "#{kind}:#{value}" } - [entry]
    trend_url(kept)
  end

  def compare_cleared = trend_url([])

  # The SVG dash-array for a Highcharts dash style, so a chip's swatch is the line it stands for.
  PLOT_DASH_ARRAYS = {"Dash" => "6 4", "Dot" => "1.5 4", "DashDot" => "8 3 2 3"}.freeze

  private

  # Everything the page is currently showing, with the comparison replaced. Built from the params
  # actually in use rather than from `request.query_parameters`, so a stale or hand-edited key
  # cannot survive a chip being removed.
  def trend_url(entries)
    filters = {"months" => month_range_param(*selected_month_range)}
    filters["compare"] = "1" if compare_previous?
    filters["compare_with"] = entries if entries.any?
    "#{request.path}?#{{filters: filters}.to_query}"
  end
end
