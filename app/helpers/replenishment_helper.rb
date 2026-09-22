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

  def forecast_skill_label(skill)
    return "—" if skill.nil?

    number_to_percentage(skill * 100, precision: 0)
  end
end
