# Provides full CRUD for DonationSites. Donation sites are the locations where people in the community can drop off
# donations.
class DonationSitesController < ApplicationController
  include Importable

  def index
    @donation_sites = current_organization.donation_sites.alphabetized
    @include_inactive_donation_sites = params[:include_inactive_donation_sites]
    @donation_sites = @donation_sites.active if @include_inactive_donation_sites.blank?

    respond_to do |format|
      format.html
      format.csv { send_data DonationSite.generate_csv(@donation_sites), filename: "DonationSites-#{Time.zone.today}.csv" }
    end
  end

  def create
    @donation_site = current_organization.donation_sites.new(donation_site_params)
    respond_to do |format|
      if @donation_site.save
        format.html do
          redirect_to donation_sites_path,
                      notice: "Donation site #{@donation_site.name} added!"
        end
        format.js
      else
        format.html do
          flash.now[:error] = "Something didn't work quite right -- try again?"
          render action: :new
        end
        format.js { render template: "donation_sites/new_modal" }
      end
    end
  end

  def new
    @donation_site = current_organization.donation_sites.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "donation_sites/new_modal" }
      end
    end
  end

  def edit
    @donation_site = current_organization.donation_sites.find(params[:id])
  end

  def show
    @donation_site = current_organization.donation_sites.find(params[:id])
  end

  def update
    @donation_site = current_organization.donation_sites.find(params[:id])
    if @donation_site.update(donation_site_params)
      redirect_to donation_sites_path, notice: "#{@donation_site.name} updated!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def deactivate
    donation_site = current_organization.donation_sites.find(params[:id])
    begin
      donation_site.deactivate!
    rescue => e
      flash[:error] = e.message
      redirect_back(fallback_location: donation_sites_path)
      return
    end

    flash[:notice] = "#{donation_site.name} has been deactivated."
    redirect_to donation_sites_path
  end

  def reactivate
    donation_site = current_organization.donation_sites.find(params[:id])
    begin
      donation_site.reactivate!
    rescue => e
      flash[:error] = e.message
      redirect_back(fallback_location: donation_sites_path)
      return
    end

    flash[:notice] = "#{donation_site.name} has been reactivated."
    redirect_to donation_sites_path
  end

  private

  def donation_site_params
    params.require(:donation_site).permit(:name, :address, :contact_name, :email, :phone)
  end

  helper_method \
    def filter_params
    {}
  end
end
