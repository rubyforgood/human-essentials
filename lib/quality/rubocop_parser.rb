# frozen_string_literal: true

require "json"

module Quality
  class RubocopParser
    COPS = {
      class_length_max: "Metrics/ClassLength",
      module_length_max: "Metrics/ModuleLength",
      method_length_max: "Metrics/MethodLength",
      abc_size_max: "Metrics/AbcSize",
      cyclomatic_complexity_max: "Metrics/CyclomaticComplexity",
      perceived_complexity_max: "Metrics/PerceivedComplexity"
    }.freeze

    MEASURE_RE = %r{([\d.]+)/[\d.]+}

    def initialize(path)
      @path = path
    end

    def parse
      offenses = JSON.parse(File.read(@path)).fetch("files").flat_map { |f| f["offenses"] }
      COPS.transform_values { |cop_name| max_for(cop_name, offenses) }
    end

    private

    def max_for(cop_name, offenses)
      values = offenses
        .select { |o| o["cop_name"] == cop_name }
        .map { |o| o["message"][MEASURE_RE, 1]&.to_f }
        .compact

      return nil if values.empty?

      picked = values.max
      (picked == picked.to_i) ? picked.to_i : picked
    end
  end
end
