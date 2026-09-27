# frozen_string_literal: true

module ReplenishmentHelper
  STATUS_BADGES = {
    critical: ["danger", "Order now"],
    reorder: ["warning", "Reorder"],
    ok: ["success", "OK"],
    no_demand: ["secondary", "No recent demand"]
  }.freeze

  def replenishment_status_badge(status)
    css, label = STATUS_BADGES.fetch(status.to_sym)
    content_tag(:span, label, class: "badge badge-#{css}")
  end

  def forecast_model_label(model)
    {
      "holt" => "Holt (damped trend)",
      "ses" => "Exponential smoothing",
      "moving_average" => "3-month average",
      "naive" => "Last month",
      "seasonal_naive" => "Same month last year",
      "average" => "Average (short history)",
      "none" => "—"
    }.fetch(model, model)
  end

  # A small inline line chart of monthly demand, oldest to newest.
  def replenishment_sparkline(values, width: 120, height: 28)
    values = Array(values).map(&:to_f)
    return "" if values.length < 2 || values.all?(&:zero?)

    low, high = values.minmax
    span = (high - low).nonzero? || 1.0
    step = width.to_f / (values.length - 1)
    points = values.each_with_index.map do |value, i|
      "#{(i * step).round(1)},#{(height - 2 - ((value - low) / span * (height - 4))).round(1)}"
    end.join(" ")

    content_tag(:svg, tag.polyline(points: points, fill: "none", stroke: "#007bff", "stroke-width": 1.5),
      width: width, height: height, viewBox: "0 0 #{width} #{height}", role: "img",
      "aria-label": "Monthly demand over the last #{values.length} months")
  end

  # Change in the last 3 months' average vs. the 3 months before, e.g. "+12%".
  def replenishment_trend_label(values)
    values = Array(values).map(&:to_f)
    return nil if values.length < 6

    before = values[-6..-4].sum
    return nil if before.zero?

    change = (values.last(3).sum - before) / before
    "#{"+" if change.positive?}#{(change * 100).round}%"
  end

  def forecast_skill_label(skill)
    return "—" if skill.nil?

    number_to_percentage(skill * 100, precision: 0)
  end
end
