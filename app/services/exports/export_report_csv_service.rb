module Exports
  class ExportReportCSVService
    def initialize(reporter:)
      @columns = reporter.columns
      @report = reporter.report
    end

    def generate_csv
      csv_data = generate_csv_data

      CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      csv_data = []

      # implement me !!!!
      csv_data << headers
      csv_data << build_row_data(@columns)

      csv_data
    end

    private

    attr_reader :report

    def headers
      @columns
    end

    # Returns a Hash of keys to indexes so that obtaining the index
    # doesn't require a linear scan.
    def headers_with_indexes
      @headers_with_indexes ||= headers.each_with_index.to_h
    end

    def build_row_data(columns)
      columns.map { |column| @report[column] }
    end
  end
end
