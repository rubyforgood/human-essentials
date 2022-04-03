module Reports
  class << self
    # @param year [Integer]
    # @param organization [Organization]
    # @return [Array<Reports::Report>]
    def all_reports(year:, organization:)
      [
        Reports::AcquisitionReportService.new(year: year, organization: organization).report,
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
  end
end
