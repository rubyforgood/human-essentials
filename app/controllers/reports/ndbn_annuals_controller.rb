class Reports::NdbnAnnualsController < ApplicationController
  def index
    @years = get_reports_years
    @month_remaing_to_report = 12 - Time.current.month
  end

  def show
    raise ActionController::RoutingError.new('Not Found') unless validate_show_params

    reporters = []

    @year = params[:year]
    reporter_params = { year: @year, organization: current_organization }

    acquisition_reporter = Reports::AcquisitionReportService.new(reporter_params)
    @acquisition_report = acquisition_reporter.report
    reporters << acquisition_reporter

    warehouse_reporter = Reports::WarehouseInfoReportService.new(reporter_params)
    @warehouse_report = warehouse_reporter.report
    reporters << warehouse_reporter

    adult_incontinence_reporter = Reports::AdultIncontinenceReportService.new(reporter_params)
    @adult_incontinence_report = adult_incontinence_reporter.report
    reporters << adult_incontinence_reporter

    other_products_reporter = Reports::OtherProductsReportService.new(reporter_params)
    @other_products_report = other_products_reporter.report
    reporters << other_products_reporter

    partner_info_reporter = Reports::PartnerInfoReportService.new(reporter_params)
    @partner_info_reporter = partner_info_reporter.report
    reporters << partner_info_reporter

    # Children Served report values
    @children_served_by_partner = children_served_by_partner.to_s
    @monthly_children_served = (children_served_by_partner / 12).to_s

    # Summary Information report values
    @donations = current_organization.donations
    @donations_amount = @donations.pluck(:money_raised).compact.sum.to_s

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportReportCSVService.new(reporters: reporters).generate_csv, filename: "NdbnAnnuals-#{@year}-#{Time.zone.today}.csv"
      end
    end
  end

  private

  def get_reports_years
    foundation_year = current_organization.created_at.year
    @actual_year = Time.current.year

    year_range = foundation_year...@actual_year
    year_range.to_a
  end

  def children_served_by_partner
    current_organization.partners.map do |partner|
      partner.profile.children.count
    end.sum
  end

  def validate_show_params
    return true unless params.key?(:year)

    params[:year].to_i.positive?
  end
end
