# frozen_string_literal: true

module Quality
  class MutantParser
    class ParseError < StandardError; end

    PATTERNS = {
      mutations: /^Mutations:\s+(\d+)$/,
      kills: /^Kills:\s+(\d+)$/,
      coverage: /^Coverage:\s+([\d.]+)%$/
    }.freeze

    def initialize(path)
      @path = path
    end

    def parse
      text = File.read(@path)
      extracted = PATTERNS.transform_values { |re| text.match(re)&.[](1) }

      raise ParseError, "Could not find Coverage line in #{@path}" if extracted[:coverage].nil?

      {
        mutations: extracted[:mutations].to_i,
        kills: extracted[:kills].to_i,
        kill_ratio: extracted[:coverage].to_f
      }
    end
  end
end
