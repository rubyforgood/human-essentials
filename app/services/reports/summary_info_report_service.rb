module Reports
  class SummaryInfoReportService
    attr_reader :year, :organization

    delegate :donations, to: :organization
    delegate :count,  to: :donations, prefix: true

    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        donations_count: donations_count,
        donations_amount: donations_amount,
      }
    end

    def columns_for_csv
      %i[donations donations_amount]
    end

    def donations_amount
      donations.pluck(:money_raised).compact.sum.to_s
    end
  end
end
