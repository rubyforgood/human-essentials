module Reports
  class AnnualSurveyReportService
    def initialize(organization:, year_start:, year_end:)
      @organization = organization
      @year_start = year_start
      @year_end = year_end
    end

    def call
      (@year_start..@year_end).map do |year|
        Reports.retrieve_report(organization: @organization, year: year, recalculate: true)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to retrieve annual report for year #{year}: #{e.message}")
        nil
      end.compact
    end
  end
end
