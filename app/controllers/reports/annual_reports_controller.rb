class Reports::AnnualReportsController < ApplicationController
  before_action :validate_show_params, only: [:show, :recalculate]

  def index
    foundation_year = current_organization.created_at.year
    @actual_year = Time.current.year

    @years = (foundation_year...@actual_year).to_a

    @month_remaining_to_report = 12 - Time.current.month
  end

  def show
    @year = year_param
    @report = Reports.retrieve_report(organization: current_organization, year: @year)

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportReportCSVService.new(reports: @report.all_reports).generate_csv,
                  filename: "NdbnAnnuals-#{@year}-#{Time.zone.today}.csv"
      end
    end
  end

  def recalculate
    year = year_param
    Reports.retrieve_report(organization: current_organization, year: year, recalculate: true)
    redirect_to reports_annual_report_path(year), notice: "Recalculated annual report!"
  end

  private

  def year_param
    params.require(:year)
  end

  def validate_show_params
    not_found! unless year_param.to_i.positive?
  end
end
