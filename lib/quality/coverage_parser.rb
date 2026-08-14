# frozen_string_literal: true

require "json"

module Quality
  class CoverageParser
    def initialize(path)
      @path = path
    end

    def parse
      result = JSON.parse(File.read(@path)).fetch("result")
      {line: result["line"], branch: result["branch"]}
    end
  end
end
