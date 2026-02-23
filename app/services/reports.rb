module Reports
  class << self
    # @param year [Integer]
    # @param organization [Organization]
    # @return [Array<Reports::Report>]
    def all_reports(year:, organization:)
      [
        Reports::DiaperReportService.new(year: year, organization: organization).report,
        Reports::WarehouseReportService.new(year: year, organization: organization).report,
        Reports::AdultIncontinenceReportService.new(year: year, organization: organization).report,
        Reports::PeriodSupplyReportService.new(year: year, organization: organization).report,
        Reports::OtherProductsReportService.new(year: year, organization: organization).report,
        Reports::PartnerInfoReportService.new(year: year, organization: organization).report,
        Reports::ChildrenServedReportService.new(year: year, organization: organization).report,
        Reports::SummaryReportService.new(year: year, organization: organization).report,
      ]
    end

    # @param year [Integer]
    # @param organization [Organization]
    # @param recalculate [Boolean]
    # @return [AnnualReport]
    def retrieve_report(year:, organization:, recalculate: false)
      report_attributes = { organization: organization, year: year }
      report = AnnualReport.find_or_create_by(report_attributes)
      if report.all_reports.blank? || recalculate
        calculated_reports = all_reports(**report_attributes)
        report.update!(all_reports: calculated_reports)
      end
      report
    end

    # @param organization [Organization]
    # @return [Array<Reports::Report>]
    def reports_across_the_year(organization:)
      foundation_year = organization.earliest_reporting_year
      last_completed_year = 1.year.ago.year
      years = (foundation_year..last_completed_year).to_a
      reports_across_the_year = []
      years.each do |year|
        report = retrieve_report(year: year, organization: organization)
        unless report.all_reports.blank?
          reports_across_the_year << report.all_reports.unshift(year_hash(year))
        end
      end
      reports_across_the_year
    end

    private

    # @param year [Integer]
    # @return [Hash]
    def year_hash(year)
      {
        "name" => "Report Year",
        "entries" => {
          "Year" => year.to_s
        }
      }
    end
  end
end
