# frozen_string_literal: true

module Replenishment
  # Forecasts monthly demand for a single item from its distribution history.
  #
  # Several candidate models are fitted and the one with the lowest
  # out-of-sample error on a rolling-origin backtest is chosen. The backtest
  # only ever uses data that would have been available at the time of each
  # forecast, so the reported error is an honest estimate of how wrong the
  # forecast is likely to be next month. That error (sigma) feeds the safety
  # stock calculation in ReorderPolicy.
  #
  #   result = Replenishment::DemandForecaster.new([120, 140, 90, ...], horizon: 3).call
  #   result.model     # => "holt"
  #   result.forecast  # => [131.2, 133.0, 134.8]
  #   result.sigma     # => 18.4   (typical one-month forecast error, in units)
  #
  class DemandForecaster
    ALPHAS = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9].freeze
    BETAS = [0.05, 0.1, 0.2, 0.3].freeze
    DAMPING = 0.9 # damped trend keeps Holt from extrapolating growth forever
    MIN_TRAIN = 4 # smallest history we will fit a model on
    MAX_BACKTEST_POINTS = 6

    Result = Data.define(:model, :params, :forecast, :sigma, :mae, :naive_mae, :history_length) do
      # Forecast skill vs. "next month = this month". 0.25 means 25% lower
      # error than the naive guess; negative means worse than naive.
      def skill
        return nil if naive_mae.nil? || naive_mae.zero? || mae.nil?

        1.0 - (mae / naive_mae)
      end

      def next_month
        forecast.first || 0.0
      end
    end

    def initialize(series, horizon: 3)
      @series = Array(series).map { |v| v.to_f.clamp(0, Float::INFINITY) }
      @horizon = horizon
    end

    def call
      return empty_result if @series.empty? || @series.all?(&:zero?)
      return short_history_result if @series.length < MIN_TRAIN + 1

      naive_mae = mean(backtest_errors(:naive).map(&:abs))
      scores = candidate_models.map do |name|
        errors = backtest_errors(name)
        {name:, mae: mean(errors.map(&:abs)), rmse: rmse(errors), naive_mae:}
      end

      best = scores.min_by { |s| [s[:mae], model_complexity(s[:name])] }
      forecast, params = fit_and_forecast(best[:name], @series, @horizon)

      Result.new(
        model: best[:name].to_s,
        params: params,
        forecast: forecast.map { |f| f.clamp(0, Float::INFINITY).round(1) },
        sigma: best[:rmse].round(2),
        mae: best[:mae].round(2),
        naive_mae: best[:naive_mae].round(2),
        history_length: @series.length
      )
    end

    private

    def candidate_models
      models = %i[naive moving_average ses holt]
      models << :seasonal_naive if @series.length >= 24
      models
    end

    # Simpler models win ties so we don't over-fit tiny data sets.
    def model_complexity(name)
      {naive: 0, seasonal_naive: 0, moving_average: 1, ses: 2, holt: 3}.fetch(name)
    end

    # Rolling-origin evaluation: for each of the last N months, fit on
    # everything before it and record the one-step-ahead error.
    def backtest_errors(name)
      n = @series.length
      points = [MAX_BACKTEST_POINTS, n - MIN_TRAIN].min
      ((n - points)...n).map do |t|
        forecast, = fit_and_forecast(name, @series[0...t], 1)
        @series[t] - forecast.first
      end
    end

    def fit_and_forecast(name, data, horizon)
      case name
      when :naive then [Array.new(horizon, data.last), {}]
      when :seasonal_naive then [seasonal_naive(data, horizon), {season: 12}]
      when :moving_average then [Array.new(horizon, mean(data.last(3))), {window: 3}]
      when :ses then fit_ses(data, horizon)
      when :holt then fit_holt(data, horizon)
      else raise ArgumentError, "unknown model #{name}"
      end
    end

    def seasonal_naive(data, horizon)
      return Array.new(horizon, data.last) if data.length < 12

      (0...horizon).map { |h| data[data.length - 12 + (h % 12)] }
    end

    # Simple exponential smoothing; alpha chosen by in-sample one-step SSE.
    def fit_ses(data, horizon)
      alpha = ALPHAS.min_by { |a| ses_sse(data, a) }
      level = ses_level(data, alpha)
      [Array.new(horizon, level), {alpha:}]
    end

    def ses_level(data, alpha)
      data.drop(1).reduce(data.first) { |level, y| (alpha * y) + ((1 - alpha) * level) }
    end

    def ses_sse(data, alpha)
      level = data.first
      data.drop(1).sum do |y|
        err = y - level
        level = (alpha * y) + ((1 - alpha) * level)
        err**2
      end
    end

    # Holt's linear method with a damped trend.
    def fit_holt(data, horizon)
      alpha, beta = ALPHAS.product(BETAS).min_by { |a, b| holt_run(data, a, b)[:sse] }
      state = holt_run(data, alpha, beta)
      forecast = (1..horizon).map do |h|
        damp_sum = (1..h).sum { |i| DAMPING**i }
        state[:level] + (damp_sum * state[:trend])
      end
      [forecast, {alpha:, beta:, phi: DAMPING}]
    end

    def holt_run(data, alpha, beta)
      level = data.first
      trend = data[1] - data[0]
      sse = 0.0
      data.drop(1).each do |y|
        prediction = level + (DAMPING * trend)
        sse += (y - prediction)**2
        new_level = (alpha * y) + ((1 - alpha) * prediction)
        trend = (beta * (new_level - level)) + ((1 - beta) * DAMPING * trend)
        level = new_level
      end
      {level:, trend:, sse:}
    end

    def short_history_result
      avg = mean(@series)
      Result.new(model: "average", params: {}, forecast: Array.new(@horizon, avg.round(1)),
        sigma: stddev(@series).round(2), mae: nil, naive_mae: nil, history_length: @series.length)
    end

    def empty_result
      Result.new(model: "none", params: {}, forecast: Array.new(@horizon, 0.0),
        sigma: 0.0, mae: nil, naive_mae: nil, history_length: @series.length)
    end

    def mean(values)
      return 0.0 if values.empty?

      values.sum / values.length.to_f
    end

    def rmse(errors)
      Math.sqrt(mean(errors.map { |e| e**2 }))
    end

    def stddev(values)
      return 0.0 if values.length < 2

      m = mean(values)
      Math.sqrt(values.sum { |v| (v - m)**2 } / (values.length - 1))
    end
  end
end
