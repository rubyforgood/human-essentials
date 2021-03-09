class Reports::NbdnAnnualController < ApplicationController
  def index
    @years = get_reports_years
    @month_remaing_to_report = 12 - Time.current.month
  end

  def show
    raise ActionController::RoutingError.new('Not Found') unless validate_show_params
  end

  private

  def get_reports_years
    foundation_year = current_organization.created_at.year
    @actual_year = Time.current.year

    year_range = foundation_year...@actual_year
    year_range.to_a
  end

  def validate_show_params
    return true unless params.key?(:year)

    params[:year].to_i.positive?
  end
end
