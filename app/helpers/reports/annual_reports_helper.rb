module Reports
  module AnnualReportsHelper
    def available_date
      (Date.current + 1.year).beginning_of_year.strftime("%B%e, %Y")
    end
  end
end
