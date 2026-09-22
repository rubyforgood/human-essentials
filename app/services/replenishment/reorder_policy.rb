# frozen_string_literal: true

module Replenishment
  # Turns a demand forecast into a concrete replenishment decision using a
  # periodic-review, order-up-to inventory policy (the "(R, S)" policy from
  # operations textbooks):
  #
  #   safety stock   SS = z * sigma * sqrt(L)
  #   reorder point  ROP = expected demand during lead time + SS
  #   order-up-to    S   = expected demand during (L + R) + z * sigma * sqrt(L + R)
  #   order quantity Q   = S - on hand   (only when on hand <= ROP)
  #
  # where L is the lead time (how long a diaper drive or purchase takes to
  # arrive), R is the review period (how often the bank checks stock) and z
  # comes from the target service level (e.g. 95% => z = 1.645).
  #
  # Times are in days; sigma is converted from monthly to daily scale.
  class ReorderPolicy
    DAYS_PER_MONTH = 30.4

    Decision = Data.define(
      :status, :daily_demand, :safety_stock, :reorder_point, :order_up_to,
      :suggested_order, :days_of_supply, :stockout_date
    )

    def initialize(forecast:, sigma:, on_hand:, lead_time_days: 30, review_period_days: 14, service_level: 0.95, today: Date.current)
      @forecast = Array(forecast).map(&:to_f)
      @forecast = [0.0] if @forecast.empty?
      @sigma_monthly = sigma.to_f
      @on_hand = on_hand.to_i
      @lead_time = lead_time_days.to_f
      @review = review_period_days.to_f
      @service_level = service_level.to_f
      @today = today
    end

    def call
      z = self.class.z_score(@service_level)
      lead_demand = demand_over(@lead_time)
      safety_stock = z * sigma_over(@lead_time)
      reorder_point = lead_demand + safety_stock
      order_up_to = demand_over(@lead_time + @review) + (z * sigma_over(@lead_time + @review))
      daily = daily_demand

      suggested = (@on_hand <= reorder_point) ? (order_up_to - @on_hand).ceil : 0
      days_of_supply = daily.positive? ? (@on_hand / daily) : nil

      Decision.new(
        status: status_for(lead_demand, reorder_point),
        daily_demand: daily.round(2),
        safety_stock: safety_stock.ceil,
        reorder_point: reorder_point.ceil,
        order_up_to: order_up_to.ceil,
        suggested_order: [suggested, 0].max,
        days_of_supply: days_of_supply&.floor,
        stockout_date: days_of_supply && (@today + days_of_supply.floor)
      )
    end

    # Inverse of the standard normal CDF (Acklam's rational approximation,
    # accurate to ~1e-9), so any service level can be used, not just a table.
    def self.z_score(p)
      raise ArgumentError, "service level must be between 0 and 1" unless p.positive? && p < 1

      a = [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
        1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
      b = [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
        6.680131188771972e+01, -1.328068155288572e+01]
      c = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
        -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
      d = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00, 3.754408661907416e+00]
      low = 0.02425

      if p < low
        q = Math.sqrt(-2 * Math.log(p))
        (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1)
      elsif p <= 1 - low
        q = p - 0.5
        r = q * q
        (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q /
          (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
      else
        -z_score(1 - p)
      end
    end

    private

    def daily_demand
      @forecast.first / DAYS_PER_MONTH
    end

    # Expected demand over the next `days`, walking through the monthly
    # forecast so a rising or falling trend is respected.
    def demand_over(days)
      remaining = days
      total = 0.0
      month = 0
      while remaining.positive?
        rate = (@forecast[month] || @forecast.last) / DAYS_PER_MONTH
        chunk = [remaining, DAYS_PER_MONTH].min
        total += rate * chunk
        remaining -= chunk
        month += 1
      end
      total
    end

    # Forecast errors are assumed independent month to month, so variance
    # scales linearly with time and sigma with its square root.
    def sigma_over(days)
      @sigma_monthly * Math.sqrt(days / DAYS_PER_MONTH)
    end

    def status_for(lead_demand, reorder_point)
      return :no_demand if daily_demand.zero?
      return :critical if @on_hand < lead_demand # will run out before a new order can arrive
      return :reorder if @on_hand <= reorder_point

      :ok
    end
  end
end
