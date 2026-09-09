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
      csv_data = []
      return csv_data if @reports.empty?

      # Reports from different years can have different columns (fields get
      # added or renamed over time), so build the union of headers across all
      # the reports, in first-seen order, and look each report's values up by
      # header. Values a year doesn't have are left blank.
      headers = @reports.flat_map { |report|
        report.all_reports.flat_map { |r| r['entries'].keys }
      }.uniq

      csv_data << ['Year'] + headers

      @reports.each do |report|
        entries = report.all_reports.reduce({}) { |merged, r| merged.merge(r['entries']) }
        csv_data << [report['year']] + entries.values_at(*headers)
      end

      csv_data
    end
  end
end
