# frozen_string_literal: true

require "json"

module Quality
  class BrakemanParser
    def initialize(path)
      @path = path
    end

    def parse
      data = JSON.parse(File.read(@path))
      {warnings: data.fetch("warnings", []).length}
    end
  end
end
