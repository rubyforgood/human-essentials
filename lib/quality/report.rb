# frozen_string_literal: true

module Quality
  class Report
    GATES = [
      {name: "Line coverage", measure: %i[coverage line], threshold: %w[coverage line_min], cmp: :>=, unit: "%"},
      {name: "Branch coverage", measure: %i[coverage branch], threshold: %w[coverage branch_min], cmp: :>=, unit: "%"},
      {name: "Flog max (method)", measure: %i[flog method_max], threshold: %w[flog method_max], cmp: :<=, unit: ""},
      {name: "Flog max (class)", measure: %i[flog class_max], threshold: %w[flog class_max], cmp: :<=, unit: ""},
      {name: "Mutation kill ratio", measure: %i[mutation kill_ratio], threshold: %w[mutation kill_ratio_min], cmp: :>=, unit: "%"},
      {name: "Brakeman warnings", measure: %i[brakeman warnings], threshold: %w[brakeman warnings_max], cmp: :<=, unit: ""},
      {name: "RuboCop offenses", measure: %i[rubocop offenses], threshold: %w[rubocop offenses_max], cmp: :<=, unit: ""}
    ].freeze

    def initialize(measurements:, thresholds:)
      @measurements = measurements
      @thresholds = thresholds
      @gate_results = build_gate_results
    end

    def passed?
      @gate_results.all?(&:passed?)
    end

    def to_s
      lines = ["Quality gates", "============="]
      @gate_results.each do |gate|
        lines << format(
          "%-22s %-22s %s",
          gate.name,
          summary(gate),
          gate.passed? ? "\u2713" : "\u2717"
        )
      end
      lines << "#{@gate_results.count(&:passed?)}/#{@gate_results.size} gates passed."
      lines.join("\n")
    end

    private

    def summary(gate)
      "#{format_measure(gate.measure, gate.unit)} #{comparison_symbol(gate.cmp)} " \
        "#{format_number(gate.threshold)}#{gate.unit}"
    end

    GateResult = Struct.new(:name, :measure, :threshold, :cmp, :unit) do
      def passed?
        return false if measure.nil? || threshold.nil?

        case cmp
        when :>= then measure >= threshold
        when :<= then measure <= threshold
        end
      end
    end

    def build_gate_results
      GATES.map do |g|
        measured = @measurements.dig(*g[:measure])
        threshold = @thresholds.dig(*g[:threshold])
        GateResult.new(g[:name], measured, threshold, g[:cmp], g[:unit])
      end
    end

    def comparison_symbol(cmp)
      (cmp == :>=) ? ">=" : "<="
    end

    def format_measure(measure, unit)
      return "n/a" if measure.nil?

      "#{format_number(measure)}#{unit}"
    end

    def format_number(value)
      return value if value.nil?

      (value == value.to_i) ? value.to_i.to_s : value.round(2).to_s
    end
  end
end
