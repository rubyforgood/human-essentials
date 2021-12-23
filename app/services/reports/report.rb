module Reports
  class Report
    attr_accessor :entries, :name

    # @param name [String]
    # @param entries [Array<Hash<String, Object>>]
    def initialize(name, entries)
      self.name = name
      self.entries = entries
    end

    def each_entry
      self.entries.each { |hash| yield hash.keys.first, hash.values.first }
    end

  end
end
