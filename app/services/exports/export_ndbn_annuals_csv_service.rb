module Exports
  class ExportNdbnAnnualsCSVService
    def initialize(year)
      @year = year

      @data_rows = ["this is just a test", "this is the second row"]
    end

    def generate_csv
      csv_data = generate_csv_data

      CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      csv_data = []

      csv_data << headers
      data_rows.each do |data|
        csv_data << build_row_data(data)
      end

      csv_data
    end

    private

    attr_reader :year, :data_rows

    def headers
      # Build the headers in the correct order
      base_headers
    end

    # Returns a Hash of keys to indexes so that obtaining the index
    # doesn't require a linear scan.
    def headers_with_indexes
      @headers_with_indexes ||= headers.each_with_index.to_h
    end

    # This method keeps the base headers associated with the lambdas
    # for extracting the values for the base columns from the given
    # distribution.
    #
    # Doing so (as opposed to expressing them in distinct methods) makes
    # it less likely that a future edit will inadvertently modify the
    # order of the headers in a way that isn't also reflected in the
    # values for the these base columns.
    #
    # Reminder: Since Ruby 1.9, Hashes are ordered based on insertion
    # (or on the order of the literal).
    def base_table
      {
        "Header 1" => ->(obj) {
          "value"
        },
      }
    end

    def base_headers
      base_table.keys
    end

    def build_row_data(distribution)
      base_table.values.map { |closure| closure.call(distribution) }
    end
  end
end
