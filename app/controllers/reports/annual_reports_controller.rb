class Reports::AnnualReportsController < ApplicationController
  before_action :validate_show_params, only: [:show, :recalculate]
  before_action :validate_range_params, only: [:range]

  def index
    # 2813_update_annual_report -- changed to earliest_reporting_year
    # so that we can do system tests and staging
    foundation_year = current_organization.earliest_reporting_year
    @actual_year = Time.current.year

    @years = (foundation_year...@actual_year).to_a
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
    # Sort the requested years first, then clamp. Clamping each end before
    # sorting lets the sort put back what the clamps just excluded, so a range
    # entirely outside the reportable years comes back inverted and spanning it
    # (2030-2035 becoming 2026-2030, say).
    year_start, year_end = [range_params[:year_start].to_i, range_params[:year_end].to_i].minmax

    # Reports only exist from the org's first reporting year through the last
    # complete year -- the current year is still in progress.
    year_start = [year_start, current_organization.earliest_reporting_year].max
    year_end = [year_end, Time.current.year - 1].min

    # Nothing reportable overlaps the requested range. not_found! only responds
    # to html and json, so answer the csv request directly.
    return head :not_found if year_start > year_end

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
