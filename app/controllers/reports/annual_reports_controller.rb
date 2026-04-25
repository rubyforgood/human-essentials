class Reports::AnnualReportsController < ApplicationController
  before_action :validate_show_params, only: [:show, :recalculate]

  def index
    # 2813_update_annual_report -- changed to earliest_reporting_year
    # so that we can do system tests and staging
    @foundation_year = current_organization.earliest_reporting_year

    @actual_year = Time.current.year

    @years = (@foundation_year...@actual_year).to_a

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

  def range
    year_start = range_params[:year_start].to_i
    year_end = range_params[:year_end].to_i

    if year_end < year_start
      flash[:error] = "End year must be greater than or equal to start year."
      redirect_to reports_annual_reports_path and return
    end

    reports = Reports::AnnualSurveyReportService.new(organization: current_organization, year_start: year_start, year_end: year_end).call

    respond_to do |format|
      format.csv do
        send_data Exports::ExportReportCSVService.new(reports:).generate_csv(range: true),
                  filename: "NdbnAnnuals-#{year_start}-#{year_end}.csv"
      end
    end
  end

  private

  def year_param
    params.require(:year)
  end

  def range_params
    params.permit(:year_start, :year_end)
  end

  def validate_show_params
    not_found! unless year_param.to_i.positive?
  end
end
