# Exports a generic report to csv
# expects a report with a report method returns a hash with keys corresponding to columns and values corresponding to the reported value
# It should also have a columns_for_csv method to determine the order of the columns
module Exports
  class ExportReportCSVService
    def initialize(reports:)
      @reports = reports
    end

    def generate_csv(range: false)
      csv_data = range ? generate_range_csv_data : generate_csv_data

      ::CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      headers = []
      data = []

      csv_data = []

      @reports.each do |report|
        headers.concat(report['entries'].keys)
        data.concat(report['entries'].values)
      end

      csv_data << headers
      csv_data << data

      csv_data
    end

    def generate_range_csv_data
      return [] if @reports.empty?

      # Ordered unique headers (in first-seen order)
      header_index = {}

      # Cache each year's flattened entries so we don't re-walk twice
      yearly_entries = @reports.map do |report|
        entries = {}

        report.all_reports.each do |section|
          section.fetch("entries", {}).each do |key, value|
            header_index[key] ||= true
            entries[key] = value
          end
        end

        {year: report["year"], entries: entries}
      end

      headers = header_index.keys
      csv_data = []
      csv_data << ["Year"] + headers

      yearly_entries.each do |row|
        csv_data << [row[:year]] + headers.map { |h| row[:entries][h] }
      end

      csv_data
    end
  end
end
