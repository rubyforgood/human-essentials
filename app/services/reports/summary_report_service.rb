module Reports
  class SummaryReportService
    include ActionView::Helpers::NumberHelper
    attr_reader :year, :organization

    # @param year [Integer]
    # @param organization [Organization]
    def initialize(year:, organization:)
      @year = year.to_i
      @organization = organization
    end

    # @return [Hash]
    def report
      @report ||= { name: 'Year End Summary',
                    entries: {
                      '% difference in yearly donations' => percent_donations,
                      '% difference in total money donated' => percent_money,
                      '% difference in disposable diaper donations' => percent_diapers
                    } }
    end

    # @return [String]
    def percent_donations
      percent_difference(donations(year - 1), donations(year))
    end

    # @return [String]
    def percent_money
      percent_difference(money(year - 1), money(year))
    end

    # @return [String]
    def percent_diapers
      percent_difference(diapers(year - 1), diapers(year))
    end

    # @param last [Numeric]
    # @param this [Numeric]
    # @return [String]
    def percent_difference(last, this)
      if last.zero?
        if this.zero?
          "0%"
        else
          "+100%"
        end
      else
        res = (((this - last) / last.to_f) * 100).round
        return "0%" if res.zero?

        res = "#{number_with_delimiter(res)}%"
        res = "+#{res}" unless res.start_with?('-')
        res
      end
    end

    # @param year [Integer]
    # @return [Integer]
    def donations(year)
      organization.donations.for_year(year).count
    end

    # @param year [Integer]
    # @return [Float]
    def money(year)
      organization.donations.for_year(year).sum(:money_raised)
    end

    # @param year [Integer]
    # @return [Integer]
    def diapers(year)
      LineItem.joins(:item)
              .merge(Item.disposable)
              .where(itemizable: organization.donations.for_year(year))
              .sum(:quantity)
    end
  end
end
