# frozen_string_literal: true

require "flog"

module Quality
  class FlogParser
    def initialize(paths)
      @paths = Array(paths)
    end

    def parse
      flog = Flog.new
      flog.flog(*@paths)

      totals = flog.totals
      return {method_max: 0.0, class_max: 0.0} if totals.empty?

      {
        method_max: totals.values.max,
        class_max: max_class_score(totals)
      }
    end

    private

    def max_class_score(totals)
      totals
        .group_by { |method_name, _| method_name.split(/[#.]/, 2).first }
        .values
        .map { |entries| entries.sum { |_, score| score } }
        .max
    end
  end
end
