class Reports::AnnualReportsController < ApplicationController
  before_action :validate_show_params, only: [:show, :recalculate]
  before_action :validate_range_params, only: [:range]

  def index
    # 2813_update_annual_report -- changed to earliest_reporting_year
    # so that we can do system tests and staging
    @foundation_year = current_organization.earliest_reporting_year
    @current_year = Time.current.year

    @years = (@foundation_year...@current_year).to_a

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
    # Set range to be within valid reporting bounds
    # Start year cannot be before org founding year
    # End year cannot be after current year
    year_start = [range_params[:year_start].to_i, current_organization.earliest_reporting_year].max
    year_end = [range_params[:year_end].to_i, Time.current.year].min

    # Sort years if out of order
    year_start, year_end = [year_start, year_end].minmax

    reports = get_range_report(year_start, year_end)

    respond_to do |format|
      format.csv do
        send_data Exports::ExportReportCSVService.new(reports:).generate_csv(range: true),
                  filename: "NdbnAnnuals-#{year_start}-#{year_end}.csv"
      end
    end
  end

  private

  def get_range_report(year_start, year_end)
    (year_start..year_end).map do |year|
      Reports.retrieve_report(organization: current_organization, year: year, recalculate: true)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to retrieve annual report for year #{year}: #{e.message}")
      nil
    end.compact
  end

  def year_param
    params.require(:year)
  end

  def range_params
    params.permit(:year_start, :year_end)
  end

  def validate_show_params
    not_found! unless year_param.to_i.positive?
  end

  def validate_range_params
    not_found! unless range_params[:year_start] =~ year_regex && range_params[:year_end] =~ year_regex
  end

  def year_regex
    /^\d{4}$/
  end
end
