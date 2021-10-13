class Reports::NdbnAnnualsController < ApplicationController
  def index
    @years = get_reports_years
    @month_remaing_to_report = 12 - Time.current.month

    # Diaper Aquisition report values
    @diaper_drives = DiaperDrive.all
    @number_of_diapers_from_drives = number_of_diapers_from_drives
    @money_from_drives = money_from_drives
    @virtual_diaper_drives = virtual_diaper_drives
    @money_from_virtual_drives = money_from_virtual_drives
    @number_of_diapers_from_virtual_drives = number_of_diapers_from_virtual_drives

    # Warehouse Information report values
    @storage_locations = current_organization.storage_locations
    @square_footage = @storage_locations.pluck(:square_footage).sum.to_s
    @largest_location = @storage_locations.order(square_footage: :desc).first.name

    # Partner Information report values
    @partners = current_organization.partners
    @partner_agency_type = partner_agency_type
    @partner_zipcodes_serviced = partner_zipcodes_serviced

    # Summary Information report values
    @donations = current_organization.donations
    @donations_amount = @donations.pluck(:money_raised).compact.sum.to_s
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

  def annual_drives
    @diaper_drives.within_date_range("2021-01-01 - 2021-12-31")
  end

  def number_of_diapers_from_drives
    annual_drives.map(&:donation_quantity).sum
  end

  def money_from_drives
    annual_drives.map(&:in_kind_value).sum
  end

  def virtual_diaper_drives
    annual_drives.where(virtual: true)
  end

  def money_from_virtual_drives
    virtual_diaper_drives.map(&:donation_quantity).sum
  end

  def number_of_diapers_from_virtual_drives
    virtual_diaper_drives.map(&:in_kind_value).sum
  end

  def partner_agency_type
    @partners.map do |partner|
      partner.profile.agency_type
    end
  end

  def partner_zipcodes_serviced
    @partners.map do |partner|
      partner.profile.zips_served
    end
  end

  def validate_show_params
    return true unless params.key?(:year)

    params[:year].to_i.positive?
  end
end
