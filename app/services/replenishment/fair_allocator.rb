# frozen_string_literal: true

module Replenishment
  # Splits a scarce supply of one item across partner agencies whose
  # requests add up to more than the bank has on hand.
  #
  # Two policies are offered so staff can see the trade-off:
  #
  # * :proportional - every partner receives the same fraction of what it
  #   asked for (e.g. 70% of each request).
  # * :max_min      - weighted max-min fairness ("water-filling"). Supply is
  #   poured evenly across partners; anyone whose request is fully met drops
  #   out and the excess is re-poured over the rest. Small requests are
  #   fully covered, and the smallest allocation is as large as possible.
  #   Optional weights (e.g. number of children served) tilt the pour.
  #
  # Allocations are whole units, never exceed a request, and never exceed
  # supply. Leftover fractional units go to the largest remainders.
  class FairAllocator
    POLICIES = %i[proportional max_min].freeze

    Plan = Data.define(:policy, :allocations, :supply, :total_requested) do
      def allocated
        allocations.values.sum
      end

      def fill_rates
        allocations.to_h { |key, qty| [key, requested_for(key).zero? ? 1.0 : qty.to_f / requested_for(key)] }
      end

      def min_fill_rate
        fill_rates.values.min || 1.0
      end

      # Jain's fairness index over fill rates: 1.0 = everyone gets the same
      # share of their request, 1/n = one partner gets everything.
      def jain_index
        rates = fill_rates.values
        return 1.0 if rates.empty? || rates.all?(&:zero?)

        (rates.sum**2) / (rates.length * rates.sum { |r| r**2 })
      end

      def requested_for(key)
        total_requested.fetch(key, 0)
      end
    end

    def initialize(supply:, requests:, weights: {})
      @supply = [supply.to_i, 0].max
      @requests = requests.transform_values { |q| [q.to_i, 0].max }.reject { |_, q| q.zero? }
      @weights = @requests.keys.to_h { |k| [k, [weights.fetch(k, 1).to_f, 0.0001].max] }
    end

    def call(policy = :max_min)
      raise ArgumentError, "unknown policy #{policy}" unless POLICIES.include?(policy.to_sym)

      shares =
        if @requests.values.sum <= @supply
          @requests.transform_values(&:to_f)
        elsif policy.to_sym == :proportional
          proportional
        else
          water_fill
        end

      Plan.new(policy: policy.to_sym, allocations: round_to_units(shares), supply: @supply, total_requested: @requests)
    end

    def compare
      POLICIES.index_with { |policy| call(policy) }
    end

    private

    def proportional
      ratio = @supply.to_f / @requests.values.sum
      @requests.transform_values { |q| q * ratio }
    end

    def water_fill
      shares = @requests.transform_values { 0.0 }
      active = @requests.keys
      remaining = @supply.to_f

      while remaining > 1e-9 && active.any?
        weight_sum = active.sum { |k| @weights[k] }
        level = remaining / weight_sum
        # Partners who would be over-served at this level are capped at
        # their request; the rest share what's left next round.
        capped = active.select { |k| @requests[k] - shares[k] <= level * @weights[k] }

        if capped.empty?
          active.each { |k| shares[k] += level * @weights[k] }
          remaining = 0.0
        else
          capped.each do |k|
            remaining -= @requests[k] - shares[k]
            shares[k] = @requests[k].to_f
          end
          active -= capped
        end
      end
      shares
    end

    # Largest-remainder rounding so whole units add up exactly.
    def round_to_units(shares)
      floors = shares.transform_values(&:floor)
      leftover = [@supply, @requests.values.sum].min - floors.values.sum
      shares
        .sort_by { |k, v| [-(v - v.floor), k.to_s] }
        .each do |k, _|
          break if leftover <= 0
          next if floors[k] >= @requests[k]

          floors[k] += 1
          leftover -= 1
        end
      floors
    end
  end
end
