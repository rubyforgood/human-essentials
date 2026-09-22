# frozen_string_literal: true

module Replenishment
  # Produces the replenishment plan shown on the dashboard: for every active
  # item, a demand forecast plus a reorder decision based on current stock.
  class PlanService
    STATUS_ORDER = {critical: 0, reorder: 1, ok: 2, no_demand: 3}.freeze

    Settings = Data.define(:lead_time_days, :review_period_days, :service_level, :source, :months) do
      def self.from_params(params)
        new(
          lead_time_days: params.fetch(:lead_time_days, 30).to_i.clamp(1, 365),
          review_period_days: params.fetch(:review_period_days, 14).to_i.clamp(1, 180),
          service_level: params.fetch(:service_level, 0.95).to_f.clamp(0.5, 0.999),
          source: (DemandHistory::SOURCES.map(&:to_s).include?(params[:source].to_s) ? params[:source].to_sym : :distributions),
          months: params.fetch(:months, 24).to_i.clamp(6, 60)
        )
      end
    end

    Row = Data.define(:item, :history, :forecast, :decision, :on_hand) do
      def manual_minimum
        item.on_hand_minimum_quantity.to_i
      end
    end

    def initialize(organization, settings: Settings.from_params({}), today: Date.current)
      @organization = organization
      @settings = settings
      @today = today
    end

    attr_reader :settings

    def history
      @history ||= DemandHistory.new(@organization, months: @settings.months, source: @settings.source, today: @today)
    end

    def rows
      @rows ||= build_rows
    end

    def summary
      counts = rows.group_by { |r| r.decision.status }.transform_values(&:count)
      scored = rows.map(&:forecast).select { |f| f.skill }
      {
        critical: counts.fetch(:critical, 0),
        reorder: counts.fetch(:reorder, 0),
        ok: counts.fetch(:ok, 0),
        items: rows.count,
        median_skill: median(scored.map(&:skill))
      }
    end

    private

    def build_rows
      series = history.series_by_item
      inventory = View::Inventory.new(@organization.id)

      @organization.items.active.order(:name).filter_map do |item|
        on_hand = inventory.quantity_for(item_id: item.id).to_i
        demand = series.fetch(item.id, Array.new(@settings.months, 0))
        next if on_hand.zero? && demand.all?(&:zero?)

        forecast = DemandForecaster.new(demand, horizon: 3).call
        decision = ReorderPolicy.new(
          forecast: forecast.forecast,
          sigma: forecast.sigma,
          on_hand: on_hand,
          lead_time_days: @settings.lead_time_days,
          review_period_days: @settings.review_period_days,
          service_level: @settings.service_level,
          today: @today
        ).call

        Row.new(item:, history: demand, forecast:, decision:, on_hand:)
      end.sort_by { |r| [STATUS_ORDER.fetch(r.decision.status), r.decision.days_of_supply || Float::INFINITY, r.item.name] }
    end

    def median(values)
      return nil if values.empty?

      sorted = values.sort
      mid = sorted.length / 2
      sorted.length.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
    end
  end
end
