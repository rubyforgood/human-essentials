# Exports yearly reports to csv
# expects a report with a report method returns a hash with keys corresponding to columns and values corresponding to the reported value
# It should also have a columns_for_csv method to determine the order of the columns
module Exports
  class ExportYearlyReportCSVService
    def initialize(yearly_reports:)
      @yearly_reports = yearly_reports
    end

    def generate_csv
      csv_data = generate_csv_data

      ::CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      csv_data = []

      @yearly_reports.each do |yearly_report|
        headers = []
        data = []
        yearly_report.each do |report|
          headers.concat(report["entries"].keys)
          data.concat(report["entries"].values)
        end

        if csv_data.empty?
          csv_data << headers
        end

        csv_data << data
      end

      csv_data
    end
  end
end
