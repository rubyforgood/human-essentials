# frozen_string_literal: true

module Replenishment
  # Builds a month-by-month demand series for every item in an organization.
  #
  # Two sources are supported:
  #
  # * :distributions - units actually handed out. Easy to trust, but it
  #   under-counts true demand in months when the bank ran out ("censored"
  #   demand: you can't distribute diapers you don't have).
  # * :requests      - units partners asked for, whether or not they got
  #   them. Closer to true need, but only as good as partners' use of the
  #   request portal.
  #
  # Only complete months are used. The current, partial month is excluded so
  # it doesn't look like demand suddenly dropped.
  class DemandHistory
    SOURCES = %i[distributions requests].freeze

    def initialize(organization, months: 24, source: :distributions, today: Date.current)
      raise ArgumentError, "unknown source #{source}" unless SOURCES.include?(source.to_sym)

      @organization = organization
      @months = months
      @source = source.to_sym
      @last_month = today.beginning_of_month.prev_month
      @first_month = @last_month.months_ago(months - 1)
    end

    attr_reader :first_month, :last_month

    def month_labels
      (0...@months).map { |i| @first_month.months_since(i) }
    end

    # => { item_id => [qty_month_1, ..., qty_month_n] } oldest first
    def series_by_item
      buckets = (@source == :requests) ? request_buckets : distribution_buckets
      index = month_labels.each_with_index.to_h

      buckets.each_with_object(Hash.new { |h, k| h[k] = Array.new(@months, 0) }) do |((item_id, month), qty), out|
        position = index[month.to_date.beginning_of_month]
        out[item_id][position] += qty.to_i if position
      end
    end

    private

    def range
      @first_month.beginning_of_day..@last_month.end_of_month.end_of_day
    end

    def distribution_buckets
      LineItem
        .joins("INNER JOIN distributions ON distributions.id = line_items.itemizable_id AND line_items.itemizable_type = 'Distribution'")
        .where(distributions: {organization_id: @organization.id, issued_at: range})
        .group(:item_id, Arel.sql("date_trunc('month', distributions.issued_at)"))
        .sum(:quantity)
    end

    def request_buckets
      totals = Hash.new(0)
      @organization.requests.kept
        .where(created_at: range)
        .where.not(status: :cancelled)
        .find_each do |request|
          month = request.created_at.to_date.beginning_of_month
          Array(request.request_items).each do |line|
            totals[[line["item_id"].to_i, month]] += line["quantity"].to_i
          end
        end
      totals
    end
  end
end
