# Exports a generic report to csv
# expects a report with a report method returns a hash with keys corresponding to columns and values corresponding to the reported value
# It should also have a columns_for_csv method to determine the order of the columns
module Exports
  class ExportReportCSVService
    def initialize(reports:)
      @reports = reports
    end

    def generate_csv
      csv_data = generate_csv_data

      ::CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      headers = []
      data = []

      csv_data = []

      @reports.each do |report|
        headers.concat(headers(report))
        data.concat(build_row_data(report))
      end

      csv_data << headers
      csv_data << data

      csv_data
    end

    private

    attr_reader :report

    def headers(report)
      report.entries.map { |entry| entry.keys.first }
    end

    # Returns a Hash of keys to indexes so that obtaining the index
    # doesn't require a linear scan.
    def headers_with_indexes
      @headers_with_indexes ||= headers.each_with_index.to_h
    end

    def build_row_data(report)
      report.entries.map { |entry| entry.values.first }
    end
  end
end
