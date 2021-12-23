module Reports
  module AnnualReport
    class << self
      # @param year [Integer]
      # @param organization [Organization]
      # @return [Array<Reports::Report>]
      def all_reports(year:, organization:)
        [
          Reports::AcquisitionReportService.new(year: year, organization: organization).report,
          # Reports::WarehouseInfoReportService.new(year: year, organization: organization),
          # Reports::AdultIncontinenceReportService.new(year: year, organization: organization),
          # Reports::OtherProductsReportService.new(year: year, organization: organization),
          # Reports::PartnerInfoReportService.new(year: year, organization: organization),
          # Reports::ChildrenServedReportService.new(year: year, organization: organization),
          # Reports::SummaryInfoReportService.new(year: year, organization: organization),
        ]
      end
    end
  end
end
